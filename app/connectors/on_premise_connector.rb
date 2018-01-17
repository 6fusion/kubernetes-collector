require 'concurrent'
require 'benchmark'

class OnPremiseConnector
  def initialize(config)
    @config       = config
    @last_run = Time.at(0)
    @infrastructure = Infrastructure.first           # Needed for submitting machines; there's only ever 1 infrastructure
    @thread_pool = Concurrent::ThreadPoolExecutor.new(
        min_threads: 2,
        max_threads: 10,
        max_queue: 12,
        fallback_policy: :caller_runs )
  end

  def sync
    return if Infrastructure.count == 0
    start_time = Time.now

    sync_infrastructures
    sync_machines
    sync_samples

    $logger.info { "Submission finished in #{(Time.now - start_time).round} seconds" }
    @last_run = Time.now.utc
  end

  def sync_samples
    start_time = Time.now
    oldest_sample = MachineSample.where(reading_at: { "$lt" => start_time - 5.minutes}, submitted_at: nil )
                                 .order_by(reading_at: 'ASC')
                                 .first
    $logger.debug { "Oldest sample: #{oldest_sample.inspect}" }

    if oldest_sample
      start_time = oldest_sample.reading_at
      end_time = start_time + 5.minutes
      Machine.where(status: 'poweredOn').each do |machine|
        @thread_pool.post do
          begin
            machine_samples = machine.machine_samples.where(reading_at: (start_time..end_time), submitted_at: nil)
            if machine_samples.count > 0
              $logger.debug { "Submitting #{machine_samples.count} samples for #{machine.name}" }
              payload = machine.to_samples_payload(machine_samples, start_time, end_time)
              endpoint = "machines/#{machine.remote_id}/samples"
              request_api(endpoint, :post, @config, payload)
            end
          rescue => e
            # what errors should we continue on; what should we abort the app on??
            # super gross, but hard to avoid without detangling / NoSQLfying the machine/disk/nic sample code
            machine.machine_samples.where(reading_at: (start_time..end_time)).update_all("$set" => {submitted_at: nil})
            machine.disks.each{|disk|disk.disk_samples.where(reading_at: (start_time..end_time)).update_all("$set" => {submitted_at: nil})}
            machine.nics.each{|nic|nic.nic_samples.where(reading_at: (start_time..end_time)).update_all("$set" => {submitted_at: nil})}
            $logger.error e
            $logger.debug e.backtrace.join("\n")
          end
        end
      end
      @thread_pool.shutdown
      @thread_pool.wait_for_termination
    end
  end

  def sync_infrastructures
    Infrastructure.each do |infrastructure|
      if infrastructure.remote_id
         if infrastructure.updated_at >= @last_run
           $logger.debug { "Updating infrastructure #{infrastructure.name}" }
           update_infrastructure(infrastructure)
         end
      else
        $logger.info { "Creating infrastructure #{infrastructure.name}" }
        create_infrastructure(infrastructure)
      end
    end
  end

  def sync_machines
    Machine.where(deleted_at: nil).hint(deleted_at: 1).each do |machine|
      $logger.debug { "Syncing machine #{machine.inspect}" }
      @thread_pool.post do
        begin
          if machine.remote_id
            if machine.updated_at >= @last_run
              $logger.debug { "Updating machine #{machine.name} #{machine.updated_at} > #{@last_run}" }
              update_machine(machine)
            end
          else
            $logger.info { "Creating machine #{machine.name}" }
            create_machine(machine)
          end
          sync_disks(machine)
          sync_nics(machine)
          machine.update_attribute(:deleted_at, Time.now) if machine.powered_off? and (machine.machine_samples.count == 0)
        rescue => e
          $logger.error e
        end
      end
    end
    @thread_pool.shutdown
    @thread_pool.wait_for_termination
  end

  def sync_disks(machine)
    machine.disks.each do |disk|
      if disk.remote_id
        if disk.updated_at >= @last_run
          $logger.debug { "Updating disk #{disk.name} for #{machine.name}" }
          update_disk(disk)
        end
      else
        $logger.info { "Creating disk #{disk.name} for #{machine.name}" }
        create_disk(disk)
      end
    end
  end

  def sync_nics(machine)
    machine.nics.each do |nic|
      if nic.remote_id
        if nic.updated_at >= @last_run
          $logger.debug { "Updating nic #{nic.name} for #{machine.name}" }
          update_nic(nic)
        end
      else
        $logger.info { "Creating nic #{nic.name} for #{machine.name}" }
        create_nic(nic)
      end
    end
  end

  def create_infrastructure(infrastructure)
    endpoint = "organizations/#{@config.on_premise[:organization_id]}/infrastructures"
    payload = infrastructure.to_payload
    response = request_api(endpoint, :post, @config, payload)
    update_remote_id(infrastructure, response)
    $logger.debug(payload)
  end

  def update_infrastructure(infrastructure)
    endpoint = "infrastructures/#{infrastructure.remote_id}"
    payload = infrastructure.to_payload
    request_api(endpoint, :put, @config, payload)
    $logger.debug(payload)
  end

  def create_machine(machine)
    endpoint = "infrastructures/#{@infrastructure.remote_id}/machines"
    payload = machine.to_payload
    response = request_api(endpoint, :post, @config, payload)
    update_remote_id(machine, response)
  end

  def update_machine(machine)
    endpoint = "machines/#{machine.remote_id}"
    payload = machine.to_payload
    request_api(endpoint, :put, @config, payload)
  end

  def create_disk(disk)
    endpoint = "machines/#{disk.machine.remote_id}/disks"
    payload = disk.to_payload
    response = request_api(endpoint, :post, @config, payload)
    update_remote_id(disk, response)
  end

  def update_disk(disk)
    endpoint = "disks/#{disk.remote_id}"
    payload = disk.to_payload
    request_api(endpoint, :put, @config, payload)
  end

  def create_nic(nic)
    endpoint = "machines/#{nic.machine.remote_id}/nics"
    payload = nic.to_payload
    response = request_api(endpoint, :post, @config, payload)
    update_remote_id(nic, response)
  end

  def update_nic(nic)
    endpoint = "nics/#{nic.remote_id}"
    payload = nic.to_payload
    request_api(endpoint, :put, @config, payload)
  end

  def update_remote_id(structure, response)
    parameters = { remote_id: response['id'] }
    structure.update(parameters)
  end
end
