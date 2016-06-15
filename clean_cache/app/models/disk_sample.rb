# This class defines the MongoDB structure of a machine disk sample that is sent
# to the 6fusion meter
class DiskSample
  include Mongoid::Document

  field :reading_at,        type: DateTime
  field :usage_bytes,       type: Integer
  field :read_kilobytes,    type: Integer
  field :write_kilobytes,   type: Integer

  validates :reading_at,      presence: true
  validates :usage_bytes,
            :read_kilobytes,
            :write_kilobytes, presence: true, numericality: { greater_than_or_equal_to: 0 }

  belongs_to :disk
end
