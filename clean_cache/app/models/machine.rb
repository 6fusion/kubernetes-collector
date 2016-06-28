# This class defines the MongoDB structure of a machine (container)
class Machine
  include Mongoid::Document

  STATUS_POWERED_OFF = 'poweredOff'
  STATUS_POWERED_ON  = 'poweredOn'
  STATUS_PAUSED      = 'paused'

  field :remote_id,    type: String
  field :name,         type: String
  field :virtual_name, type: String
  field :cpu_count,    type: Integer
  field :cpu_speed_hz, type: Integer
  field :memory_bytes, type: Integer
  field :tags,         type: Array
  field :status,       type: String
  field :metering_status,     type: String  # PENDING,METERING,METERED
  field :last_metering_start, type: DateTime

  validates :name, :virtual_name, :status, :tags, presence: true
  validates :cpu_count,
            :cpu_speed_hz,
            :memory_bytes, presence: true, numericality: { greater_than_or_equal_to: 0 }

  has_many :disks
  has_many :nics
  has_many :machine_samples
  belongs_to :pod

  def to_payload
    { name: self.name,
      virtual_name: self.virtual_name,
      cpu_count: self.cpu_count,
      cpu_speed_hz: self.cpu_speed_hz,
      memory_bytes: self.memory_bytes,
      tags: self.tags,
      status: self.status }
  end

  def to_samples_payload(start_time, end_time)
    machine_sample = obtain_machine_sample(start_time, end_time)

    { start_time: start_time.iso8601,
      end_time: end_time.iso8601,
      machine: machine_sample,
      disks: self.disks.all.map {|disk| disk.to_samples_payload(start_time, end_time)},
      nics: self.nics.all.map {|nic| nic.to_samples_payload(start_time, end_time)} }
  end

  def obtain_machine_sample(start_time, end_time)
    machine_samples = self.machine_samples.where(reading_at: (start_time..end_time))
    count = machine_samples.count

    cpu_usage_percent = obtain_average(machine_samples, :cpu_usage_percent, count)
    memory_bytes = obtain_average(machine_samples, :memory_bytes, count).to_i

    { cpu_usage_percent: cpu_usage_percent,
      memory_bytes: memory_bytes }
  end

  def obtain_average(machine_samples, attribute, count)
    machine_samples.inject(0.0) { |sum, sample| sum + sample.send(attribute) } / count
  end
end