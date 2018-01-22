class MachineSample
  include Mongoid::Document

  field :reading_at,        type: DateTime
  field :cpu_usage_percent, type: Integer, default: 0
  field :memory_bytes,      type: Integer, default: 0

  validates :reading_at, presence: true

  belongs_to :machine

  index({ reading_at: 1, machine_id: 1 }, { unique: true, sparse: true })
  index({ submitted_at: 1 }, { expire_after_seconds: 30.minutes, background: true, sparse: true })
end
