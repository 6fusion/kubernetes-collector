# This class is responsible for collecting metrics for all containers in the cluster
class MetricsCollector

  def initialize(logger, config)
    @logger = logger
    @config = config
  end

  def collect
    @logger.info 'Collecting metrics for the infrastructure...'
    metrics = {}
    Infrastructure.first.hosts.each do |host|
      @logger.info "Collecting metrics for host #{host.ip_address}..."
      metrics_response = CAdvisorAPI::request(@config, host.ip_address, "stats/?type=docker&recursive=true&count=#{CADVISOR_SAMPLES_COUNT}")
      metrics.merge!(metrics_response)
    end

    # Transform metrics keys so they can match a docker container ID
    metrics.keys.each {|k| metrics[k.split('/').last.split('docker-').last.split('.scope').first] = metrics.delete(k)}

    Machine.all.each do |machine|
      @logger.info("Collecting metrics for #{machine.name} container...")
      previous_sample = nil
      samples = metrics["#{machine.virtual_name}"]
      samples.each do |sample|
        if previous_sample
          machine_sample = machine.machine_samples.new(reading_at: sample['timestamp'])
          if sample['has_cpu']
            machine_sample.cpu_usage_percent = ((sample['cpu']['usage']['total'] - previous_sample['cpu_usage']).abs / (1000000000.0 * machine.cpu_count)) * 100
          end unless sample['cpu'].empty?
          if sample['has_memory']
            machine_sample.memory_bytes = sample['memory']['usage']
          end unless sample['memory'].empty?
          machine_sample.save!

          if sample['has_diskio']
            disk_sample = machine.disks.first.disk_samples.new(reading_at: sample['timestamp'])
            disk_sample.reading_at = sample['timestamp']
            disk_sample.usage_bytes = 1024
            disk_sample.read_kilobytes = (sample['diskio']['io_service_bytes'][0]['stats']['Read'] - previous_sample['diskio_bytes_read']).abs / 1024
            disk_sample.write_kilobytes = (sample['diskio']['io_service_bytes'][0]['stats']['Write'] - previous_sample['diskio_bytes_write']).abs / 1024
            disk_sample.save!
          end unless sample['diskio'].empty?

          if sample['has_network']
            nic_sample = machine.nics.first.nic_samples.new(reading_at: sample['timestamp'])
            nic_sample.reading_at = sample['timestamp']
            nic_sample.receive_kilobits = (sample['network']['interfaces'][0]['rx_bytes'] - previous_sample['network_bytes_receive']) * 8 / 1000
            nic_sample.transmit_kilobits = (sample['network']['interfaces'][0]['tx_bytes'] - previous_sample["network_bytes_transmit"]) * 8 / 1000
            nic_sample.save!
          end unless sample['network'].empty?
        end

        previous_sample = {}
        previous_sample['cpu_usage'] = 0
        previous_sample['diskio_bytes_read'] = 0
        previous_sample['diskio_bytes_write'] = 0
        previous_sample['network_bytes_receive'] = 0
        previous_sample['network_bytes_transmit'] = 0

        if sample['has_cpu']
          previous_sample['cpu_usage'] = sample['cpu']['usage']['total']
        end unless sample['cpu'].empty?

        if sample['has_diskio']
          previous_sample['diskio_bytes_read'] = sample['diskio']['io_service_bytes'][0]['stats']['Read']
          previous_sample['diskio_bytes_write'] = sample['diskio']['io_service_bytes'][0]['stats']['Write']
        end unless sample['diskio'].empty?

        if sample['has_network']
          previous_sample['network_bytes_receive'] = sample['network']['interfaces'][0]['rx_bytes']
          previous_sample['network_bytes_transmit'] = sample['network']['interfaces'][0]['tx_bytes']
        end unless sample['network'].empty?
      end if samples
      @logger.info("Collected metrics for #{machine.name} successfully.")
    end
  end

end