class Disk
  include Mongoid::Document

  field :remote_id,     type: String
  field :name,          type: String
  field :storage_bytes, type: Integer

  validates :name,          presence: true
  validates :storage_bytes, presence: true, numericality: { greater_than_or_equal_to: 0 }

  has_many   :disk_samples
  belongs_to :machine
end