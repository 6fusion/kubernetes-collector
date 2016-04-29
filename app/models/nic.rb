class Nic
  include Mongoid::Document

  field :remote_id,   type: String
  field :name,        type: String
  field :kind,        type: String

  validates :name,
            :kind, presence: true

  has_many   :nic_samples
  belongs_to :machine

  def to_payload
    { name: self.name,
      kind: self.kind }
  end

  def to_samples_payload(start_time, end_time) 
    nic_samples = self.nic_samples.where(reading_at: (start_time..end_time))
    count = nic_samples.count

    receive_kilobits = obtain_average(nic_samples, :receive_kilobits, count) 
    transmit_kilobits = obtain_average(nic_samples, :transmit_kilobits, count) 

    { id: self.remote_id,
      receive_bytes_per_second: receive_kilobits,
      transmit_bytes_per_second: transmit_kilobits }
  end

  def obtain_average(nic_samples, attribute, count)
    count > 0 ? (nic_samples.inject(0.0) { |sum, sample| sum + sample.send(attribute) } / count).to_i : 0
  end
end