class Host
  include Mongoid::Document

  field :ip_address,    type: String
  field :memory_bytes,  type: Integer

  validates :ip_address, presence: true
  validates :memory_bytes, presence: true, numericality: { greater_than_or_equal_to: 0 }

  has_many  :host_cpus
  has_many  :host_nics
  has_many  :host_disks
  belongs_to :infrastructure
end