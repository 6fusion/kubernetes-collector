class NicSample
  include Mongoid::Document

  field :reading_at,        type: DateTime
  field :transmit_bytes_per_second, type: Integer, default: 0
  field :receive_bytes_per_second, type: Integer, default: 0
  field :machine_custom_id, type: String

  belongs_to :nic

  index({ reading_at: 1 })
  index({ submitted_at: 1 }, { expire_after_seconds: 30.minutes, background: true, sparse: true })
end
