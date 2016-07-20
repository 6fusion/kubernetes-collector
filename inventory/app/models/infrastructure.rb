# This class defines the MongoDB structure of the infrastructure
class Infrastructure
  include Mongoid::Document

  field :remote_id,       type: String
  field :organization_id, type: String
  field :name,            type: String
  field :tags,            type: Array

  validates :organization_id, :name, :tags, presence: true

  has_many :networks
  has_many :hosts
  has_many :pods

  def to_payload
    { name: self.name,
      tags: self.tags,
      networks: self.networks.all.map {|network| network.to_payload},
      hosts: self.hosts.all.map {|host| host.to_payload} }
  end
end
