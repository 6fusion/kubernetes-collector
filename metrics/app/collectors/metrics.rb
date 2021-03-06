# This class is responsible for collecting metrics for all containers in the cluster
class MetricsCollector

  def initialize(logger, config)
    @logger = logger
    @config = config
  end

  def collect
    @logger.info 'Collecting metrics for the infrastructure...'

    metered_machines = 0

    get_candidate_machines_to_be_metered.each do |machine|
      if machine_unlocked? machine
        machine.locked = true
        machine.locked_by = @config.container[:hostname]
        machine.metering_status = 'METERING'
        machine.last_metering_start = Time.now
        machine.save!
      end
    end

    get_final_machines_to_be_metered.each do |machine|
      next if not machine_free_to_meter? machine
      metered_machines += 1
      @logger.info "Collecting metrics for #{machine.name} container..."
      metrics = CAdvisorAPI::request(@config, machine.host_ip_address, "stats/#{machine.virtual_name}/?type=docker&count=#{CADVISOR_SAMPLES_COUNT}")
      previous_sample = nil
      samples = metrics[metrics.keys.first]
      samples.each do |sample|
        if previous_sample
          machine_sample = machine.machine_samples.new(reading_at: sample['timestamp'])
          if sample['has_cpu']
            unless sample['cpu'].empty?
              machine_sample.cpu_usage_percent = ((sample['cpu']['usage']['total'] - previous_sample['cpu_usage']).abs / (1000000000.0 * machine.cpu_count)) * 100
            end
          end 
          if sample['has_memory']
            unless sample['memory'].empty?
              machine_sample.memory_bytes = sample['memory']['usage']
            end
          end 
          machine_sample.save!

          disk_sample = machine.disks.first.disk_samples.new(reading_at: sample['timestamp'])
          if sample['has_diskio']
            unless sample['diskio'].empty?
              disk_sample.reading_at = sample['timestamp']
              disk_sample.read_kilobytes = (sample['diskio']['io_service_bytes'][0]['stats']['Read'] - previous_sample['diskio_bytes_read']).abs / 1024
              disk_sample.write_kilobytes = (sample['diskio']['io_service_bytes'][0]['stats']['Write'] - previous_sample['diskio_bytes_write']).abs / 1024
            end
          end 
          if sample["has_filesystem"]
            unless sample["filesystem"].empty?
              disk_sample.usage_bytes = sample["filesystem"][0]["usage"]
            end
          end 
          disk_sample.save!

          if sample['has_network']
            unless sample['network'].empty?
              nic_sample = machine.nics.first.nic_samples.new(reading_at: sample['timestamp'])
              nic_sample.reading_at = sample['timestamp']
              nic_sample.receive_kilobits = (sample['network']['interfaces'][0]['rx_bytes'] - previous_sample['network_bytes_receive']) * 8 / 1000
              nic_sample.transmit_kilobits = (sample['network']['interfaces'][0]['tx_bytes'] - previous_sample["network_bytes_transmit"]) * 8 / 1000
              nic_sample.save!
            end
          end 
        end

        previous_sample = {}
        previous_sample['cpu_usage'] = 0
        previous_sample['diskio_bytes_read'] = 0
        previous_sample['diskio_bytes_write'] = 0
        previous_sample['network_bytes_receive'] = 0
        previous_sample['network_bytes_transmit'] = 0

        if sample['has_cpu']
          unless sample['cpu'].empty?
            previous_sample['cpu_usage'] = sample['cpu']['usage']['total']
          end
        end 

        if sample['has_diskio']
          unless sample['diskio'].empty?
            previous_sample['diskio_bytes_read'] = sample['diskio']['io_service_bytes'][0]['stats']['Read']
            previous_sample['diskio_bytes_write'] = sample['diskio']['io_service_bytes'][0]['stats']['Write']
          end
        end 

        if sample['has_network']
          unless sample['network'].empty?
            previous_sample['network_bytes_receive'] = sample['network']['interfaces'][0]['rx_bytes']
            previous_sample['network_bytes_transmit'] = sample['network']['interfaces'][0]['tx_bytes']
          end
        end 
      end if samples

      machine.locked = false
      machine.locked_by = ''
      machine.metering_status = 'METERED'
      machine.save!
      @logger.info("Collected metrics for #{machine.name} successfully.")
    end
    if metered_machines > 0
      @logger.info("Total machines metered in this run: #{metered_machines}")
    else
      @logger.info('Found no machines to be metered. Waiting for the next run.')
    end
  end

  def get_candidate_machines_to_be_metered
    Machine.where(status: 'poweredOn')
      .or(
        { metering_status: 'PENDING' },
        { metering_status: 'METERING', :last_metering_start.lt => Time.now - METERING_TIMEOUT }
      )
      .limit(MACHINES_LIMIT)
  end

  def get_final_machines_to_be_metered
    Machine.where(locked:          true,
                  locked_by:       @config.container[:hostname],
                  status:          'poweredOn',
                  metering_status: 'METERING')
  end

  def machine_unlocked?(machine)
    not machine.locked ||
    (machine.locked && machine.locked_by == @config.container[:hostname])
  end

  def machine_free_to_meter?(machine)
    machine.reload
    machine.locked &&
    machine.locked_by == @config.container[:hostname] &&
    machine.status == 'poweredOn' &&
    machine.metering_status == 'METERING'
  end

end
