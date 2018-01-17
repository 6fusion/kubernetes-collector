class Nic
  include Mongoid::Document
  include Mongoid::Timestamps

  field :remote_id,   type: String
  field :name,        type: String
  field :kind,        type: String, default: 'LAN'
  field :status,      type: String

  has_many   :nic_samples
  belongs_to :machine, index: true

  index({ deleted_at: 1 }, { expire_after_seconds: 1.day, background: true, sparse: true })

  def to_payload
    { name: self.name,
      kind: self.kind }
  end

  def to_samples_payload(start_time, end_time)
    nic_samples = self.nic_samples.where(reading_at: (start_time..end_time))
    count = nic_samples.count

    receive_bytes_per_second = obtain_average(nic_samples, :receive_bytes_per_second, count)
    transmit_bytes_per_second = obtain_average(nic_samples, :transmit_bytes_per_second, count)

    nic_samples.update_all("$set" => {submitted_at: Time.now})

    { id: self.remote_id,
      receive_bytes_per_second: receive_bytes_per_second,
      transmit_bytes_per_second: transmit_bytes_per_second }
  end

  def obtain_average(nic_samples, attribute, count)
    count > 0 ? (nic_samples.inject(0.0) { |sum, sample| sum + sample.send(attribute) } / count).to_i : 0
  end
end
