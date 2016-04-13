class Disk
  include Mongoid::Document
  
  field :remote_id,          type: String
  field :name,               type: String
  field :maximum_size_bytes, type: Integer 
  field :type,				 type: String

  validates :remote_id,          presence: true, uniqueness: true
  validates :name, :type,        presence: true
  validates :maximum_size_bytes, presence: true, numericality: { greater_than_or_equal_to: 0 }

  has_many   :disk_samples
  belongs_to :machine
end