class HostCpu
  include Mongoid::Document

  field :cores,    type: Integer
  field :speed_hz, type: Integer

  validates :cores, presence: true, numericality: { greater_than_or_equal_to: 1 }
  validates :speed_hz, presence: true, numericality: { greater_than_or_equal_to: 1 }

  belongs_to :host
end