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
    receive_kilobits = (self.nic_samples.where(reading_at: (start_time..end_time)).inject(0.0) { |sum, sample| sum + sample.receive_kilobits } / self.nic_samples.count).to_i
    transmit_kilobits = (self.nic_samples.where(reading_at: (start_time..end_time)).inject(0.0) { |sum, sample| sum + sample.transmit_kilobits } / self.nic_samples.count).to_i

    {
      id: self.remote_id,
      receive_bytes_per_second: receive_kilobits,
      transmit_bytes_per_second: transmit_kilobits
    }
  end
end