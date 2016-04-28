class HostNic
  include Mongoid::Document

  field :name,                  type: String
  field :network_name,          type: String
  field :speed_bits_per_second, type: Integer

  validates :name, presence: true

  belongs_to :host

  def to_payload
    { name: self.name,
      network_name: self.network_name,
      speed_bits_per_second: self.speed_bits_per_second }
  end
end