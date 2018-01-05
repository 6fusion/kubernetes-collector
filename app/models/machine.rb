class Machine
  include Mongoid::Document
  include Mongoid::Timestamps

  STATUS_POWERED_OFF = 'Deleted'
  STATUS_POWERED_ON  = 'poweredOn'
  STATUS_PAUSED      = 'paused'
  
  field :custom_id,           type: String
  field :remote_id,           type: String
  field :name,                type: String
  field :virtual_name,        type: String
  field :cpu_count,           type: Integer
  field :cpu_speed_hz,        type: Integer
  field :memory_bytes,        type: Integer
  field :tags,                type: Set,    default: ['type:container', 'platform:Kubernetes']
  field :status,              type: String
  field :metering_status,     type: String  # PENDING,METERING,METERED
  field :last_metering_start, type: DateTime
  field :host_ip,             type: String
  field :locked,              type: Boolean
  field :locked_by,           type: String
  field :container_name,      type: String
  field :pod_id,              type: String
  field :pod_name,            type: String
  field :is_pod_container,    type: Boolean
  field :pod_uid,             type: String
  field :pod_ip,              type: String
  field :namespace,           type: String


  validates :name, :status, :tags, presence: true
  validates :cpu_count,
            :cpu_speed_hz,
            :memory_bytes, presence: true, numericality: { greater_than_or_equal_to: 0 }

  has_many :disks, dependent: :delete
  has_many :nics,  dependent: :delete
  has_many :machine_samples
  belongs_to :pod


  index({ status: 1, is_pod_container: 1 }, { background: true })
  index({ deleted_at: 1 }, { expire_after_seconds: 1.day, background: true, sparse: true })

  def to_payload
    { custom_id: self.custom_id,
      name: self.name,
      virtual_name: self.virtual_name,
      cpu_count: self.cpu_count,
      cpu_speed_hz: self.cpu_speed_hz,
      memory_bytes: self.memory_bytes,
      tags: self.tags,
      status: self.status }
  end

  # TODO disk/nic samples should be related by IDs, not times
  def to_samples_payload(machine_samples, start_time, end_time)
    $logger.debug { "Averaging #{machine_samples.count} samples for machine: #{self.name}, time span: #{start_time} -> #{end_time}x" }
    payload = { start_time: start_time.iso8601,
                end_time: end_time.iso8601,
                machine: average_machine_samples(machine_samples.to_a),
                disks: self.disks.all.map {|disk| disk.to_samples_payload(start_time, end_time) },
                nics: self.nics.all.map {|nic| nic.to_samples_payload(start_time, end_time)} }
    machine_samples.update_all("$set" => {submitted_at: Time.now})
    payload
  end

  def average_machine_samples(machine_samples)
    count = machine_samples.count
    cpu_usage_percent = obtain_average(machine_samples, :cpu_usage_percent, count)
    memory_bytes = obtain_average(machine_samples, :memory_bytes, count).to_i

    { cpu_usage_percent: cpu_usage_percent,
      memory_bytes: memory_bytes }
  end

  def obtain_average(machine_samples, attribute, count)
    machine_samples.inject(0.0) { |sum, sample| sum + sample.send(attribute) } / count
  end

  def powered_off?
    self.status == 'Deleted'
  end

end
