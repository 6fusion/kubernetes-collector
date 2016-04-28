class HostDisk
  include Mongoid::Document

  field :name,                  type: String
  field :storage_bytes,         type: Integer
  field :speed_bits_per_second, type: Integer

  validates :name, presence: true

  belongs_to :host

  def to_payload
    { name: self.name,
      storage_bytes: self.storage_bytes,
      speed_bits_per_second: self.speed_bits_per_second }
  end
end