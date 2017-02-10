# This class defines the MongoDB structure of an infrastructure host disk
class HostDisk
  include Mongoid::Document

  field :name,                  type: String
  field :storage_bytes,         type: Integer
  field :speed_bits_per_second, type: Integer

  validates :name, presence: true

  belongs_to :host

  def default_disk_io
    ENV['DEFAULT_DISK_IO'].to_i || 1_000_000
  end

  def speed_bits_per_second_or_default
    self.speed_bits_per_second.to_i > 0 ? self.speed_bits_per_second : default_disk_io
  end

  def to_payload
    { name: self.name,
      storage_bytes: self.storage_bytes,
      speed_bits_per_second: speed_bits_per_second_or_default }
  end
end