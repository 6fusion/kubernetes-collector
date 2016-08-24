# This class defines the MongoDB structure of an infrastructure network
class Network
  include Mongoid::Document

  field :name,                  type: String
  field :kind,                  type: String
  field :speed_bits_per_second, type: Integer
  field :cost_per_hour,         type: Float

  validates :name, :kind, :speed_bits_per_second, presence: true

  belongs_to :infrastructure

  def to_payload
    { name: self.name,
      kind: self.kind,
      speed_bits_per_second: self.speed_bits_per_second,
      cost_per_hour: self.cost_per_hour }
  end
end