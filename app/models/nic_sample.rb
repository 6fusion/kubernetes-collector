class NicSample
  include Mongoid::Document

  field :reading_at,        type: DateTime
  field :transmit_kilobits, type: Integer
  field :receive_kilobits,  type: Integer

  validates :reading_at,        presence: true
  validates :transmit_kilobits, 
            :receive_kilobits,  presence: true, numericality: { greater_than_or_equal_to: 0 }

  belongs_to :nic
end