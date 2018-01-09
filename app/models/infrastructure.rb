# This class defines the MongoDB structure of the infrastructure
class Infrastructure
  include Mongoid::Document
  include Mongoid::Timestamps

  field :remote_id,       type: String
  field :name,            type: String
  field :tags,            type: Array
  field :status,          type: String, default: 'Active'

  validates :name, :tags, presence: true

  has_many :networks
  has_many :hosts
  has_many :pods

  # Note: If missing LAN or WAN, will include a fake for sake of submitting capacity defaults to API
  def networks_with_fakes
    n_w_f = self.networks.all.map {|network| network.to_payload}

    num_lan = n_w_f.select{|n| n[:kind] == 'LAN' }.size
    n_w_f << Network.fake(kind: 'LAN').to_payload unless num_lan > 0

    num_wan = n_w_f.select{|n| n[:kind] == 'WAN' }.size
    n_w_f << Network.fake(kind: 'WAN').to_payload unless num_wan > 0

    n_w_f
  end

  def to_payload
    { name: self.name,
      status: self.status,
      tags: self.tags,
      networks: networks_with_fakes,
      hosts: self.hosts.all.map {|host| host.to_payload}}
  end
end
