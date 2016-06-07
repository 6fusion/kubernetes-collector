# This class defines the MongoDB structure of a machine sample that is sent to the 6fusion meter
class MachineSample
  include Mongoid::Document

  field :reading_at,        type: DateTime
  field :cpu_usage_percent, type: Integer
  field :memory_bytes,      type: Integer

  validates :reading_at,      presence: true
  validates :cpu_usage_percent,
            :memory_bytes,    presence: true, numericality: { greater_than_or_equal_to: 0 }

  belongs_to :machine
end