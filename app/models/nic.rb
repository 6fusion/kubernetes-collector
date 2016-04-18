class Nic
  include Mongoid::Document
  
  field :remote_id,   type: String
  field :name,        type: String
  field :kind,        type: String
  field :ip_address,  type: String
  field :mac_address, type: String

  validates :name, 
            :kind,
            :ip_address,
            :mac_address, presence: true

  has_many   :nic_samples
  belongs_to :machine
end