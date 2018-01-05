class DiskSample
  include Mongoid::Document

  field :reading_at,             type: DateTime
  field :usage_bytes,            type: Integer, default: 0
  field :read_bytes_per_second,  type: Integer, default: 0
  field :write_bytes_per_second, type: Integer, default: 0

  belongs_to :disk

  index({ reading_at: 1 })
  index({submitted_at: 1}, {expire_after_seconds: 30.minutes, sparse: true, background: true})
end
