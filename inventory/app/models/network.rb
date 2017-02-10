# This class defines the MongoDB structure of an infrastructure network
class Network
  include Mongoid::Document

  field :name,                  type: String
  field :kind,                  type: String
  field :speed_bits_per_second, type: Integer
  field :cost_per_hour,         type: Float

  validates :name, :kind, :speed_bits_per_second, presence: true

  belongs_to :infrastructure

  def self.fake(kind:)
    self.new(name: "default_#{kind}",
             kind: kind,
             speed_bits_per_second: 0, # 0 will trigger default
             cost_per_hour: 0)
  end

  def default_lan
    ENV['DEFAULT_LAN_IO'].to_i || 1_000_000
  end

  def default_wan
    ENV['DEFAULT_WAN_IO'].to_i || 1_000_000
  end

  def speed_bits_per_second_or_default
    case self.kind
    when 'LAN'
      self.speed_bits_per_second.to_i > 0 ? self.speed_bits_per_second : default_lan
    when 'WAN'
      self.speed_bits_per_second.to_i > 0 ? self.speed_bits_per_second : default_wan
    else
      self.speed_bits_per_second
    end
  end

  def to_payload
    { name: self.name,
      kind: self.kind,
      speed_bits_per_second: speed_bits_per_second_or_default,
      cost_per_hour: self.cost_per_hour }
  end
end