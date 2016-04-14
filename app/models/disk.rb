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
    usage_bytes = (self.disk_samples.where(reading_at: (start_time..end_time)).inject(0.0) { |sum, sample| sum + sample.usage_bytes } / self.disk_samples.count).to_i
    read_kilobytes = (self.disk_samples.where(reading_at: (start_time..end_time)).inject(0.0) { |sum, sample| sum + sample.read_kilobytes } / self.disk_samples.count).to_i
    write_kilobytes = (self.disk_samples.where(reading_at: (start_time..end_time)).inject(0.0) { |sum, sample| sum + sample.write_kilobytes } / self.disk_samples.count).to_i

    { id: self.remote_id,
      usage_bytes: usage_bytes, 
      read_bytes_per_second: read_kilobytes, 
      write_bytes_per_second: write_kilobytes }
  end
end