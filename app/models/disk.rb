class Disk
  include Mongoid::Document

  field :remote_id,     type: String
  field :name,          type: String
  field :storage_bytes, type: Integer

  validates :name,          presence: true
  validates :storage_bytes, presence: true, numericality: { greater_than_or_equal_to: 0 }

  has_many   :disk_samples
  belongs_to :machine

  def to_payload
    { name: self.name,
      storage_bytes: self.storage_bytes }
  end

  def to_samples_payload(start_time, end_time)
    disk_samples = self.disk_samples.where(reading_at: (start_time..end_time))
    count = disk_samples.count

    usage_bytes = obtain_average(disk_samples, :usage_bytes, count) 
    read_kilobytes = obtain_average(disk_samples, :read_kilobytes, count) 
    write_kilobytes = obtain_average(disk_samples, :write_kilobytes, count) 

    { id: self.remote_id,
      usage_bytes: usage_bytes, 
      read_bytes_per_second: read_kilobytes, 
      write_bytes_per_second: write_kilobytes }
  end

  def obtain_average(disk_samples, attribute, count)
    count > 0 ? (disk_samples.inject(0.0) { |sum, sample| sum + sample.send(attribute) } / count).to_i : 0
  end
end