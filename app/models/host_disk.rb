class HostDisk
  include Mongoid::Document

  field :name,                  type: String
  field :storage_bytes,         type: Integer
  field :speed_bits_per_second, type: Integer

  validates :name, presence: true

  belongs_to :host
end