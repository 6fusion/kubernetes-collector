class Infrastructure
  include Mongoid::Document

  field :remote_id,       type: String
  field :organization_id, type: String
  field :name,            type: String
  field :tags,            type: Array

  validates :organization_id, :name, :tags, presence: true

  has_many :hosts
  has_many :pods
end