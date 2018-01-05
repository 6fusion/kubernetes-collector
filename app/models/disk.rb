class Disk
  include Mongoid::Document
  include Mongoid::Timestamps

  field :remote_id,     type: String
  field :name,          type: String
  field :storage_bytes, type: Integer
  field :status,        type: String

  validates :name,          presence: true
  validates :storage_bytes, presence: true, numericality: { greater_than_or_equal_to: 0 }

  has_many   :disk_samples
  belongs_to :machine, index: true

  index({ deleted_at: 1 }, { expire_after_seconds: 1.day, background: true, sparse: true })

  def to_payload
    { name: self.name,
      storage_bytes: self.storage_bytes }
  end

  def to_samples_payload(start_time, end_time)
    disk_samples = self.disk_samples.where(reading_at: (start_time..end_time))
    count = disk_samples.count

    usage_bytes = obtain_average(disk_samples, :usage_bytes, count)
    read_bytes = obtain_average(disk_samples, :read_bytes_per_second, count)
    write_bytes = obtain_average(disk_samples, :write_bytes_per_second, count)

    disk_samples.update_all("$set" => {submitted_at: Time.now})

    { id: self.remote_id,
      usage_bytes: usage_bytes,
      read_bytes_per_second: read_bytes,
      write_bytes_per_second: write_bytes }
  end

  def obtain_average(disk_samples, attribute, count)
    count > 0 ? (disk_samples.inject(0.0) { |sum, sample| sum + sample.send(attribute) } / count).to_i : 0
  end
end
