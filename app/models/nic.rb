class Nic
  include Mongoid::Document

  field :remote_id,   type: String
  field :name,        type: String
  field :kind,        type: String

  validates :name,
            :kind, presence: true

  has_many   :nic_samples
  belongs_to :machine
end