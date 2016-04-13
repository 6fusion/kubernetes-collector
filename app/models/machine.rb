class Machine 
  include Mongoid::Document

  field :remote_id,            type: String     
  field :name,                 type: String     
  field :virtual_name,         type: String     
  field :cpu_count,            type: Integer
  field :cpu_speed_mhz,        type: Integer
  field :maximum_memory_bytes, type: Integer
  field :tags,                 type: Array
  field :status,               type: String     

  validates :remote_id,                           presence: true, uniqueness: true
  validates :name, :virtual_name, :status, :tags, presence: true
  validates :cpu_count,    
            :cpu_speed_mhz,
            :maximum_memory_bytes,                presence: true, numericality: { greater_than_or_equal_to: 0 }

  has_many :disks
  has_many :nics
  has_many :machine_samples
end