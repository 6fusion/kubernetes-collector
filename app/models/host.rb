# This class defines the MongoDB structure of an infrastructure host
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

  def to_payload
    { cpus: self.host_cpus.all.map {|cpu| cpu.to_payload},
      memory_bytes: self.memory_bytes,
      nics: self.host_nics.all.map {|nic| nic.to_payload},
      disks: self.host_disks.all.map {|disk| disk.to_payload} }
  end
end
