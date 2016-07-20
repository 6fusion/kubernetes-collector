# This class defines the MongoDB structure of a cluster pod
class Pod
  include Mongoid::Document

  field :name, type: String

  validates :name, :infrastructure, presence: true

  has_many   :machines
  belongs_to :infrastructure
end