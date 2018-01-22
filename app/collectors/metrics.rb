class MetricsCollector

  def initialize(config)
    @config = config
    @summary_stats = Hash.new{|h,k|h[k]={}}  # reset our "cache" at the start of each collection
  end

  def collect_pod_summaries
    $logger.info { 'Collecting NIC and disk usage for the cluster' }
    @summary_stats = Hash.new{|h,k|h[k]={}}  # reset our "cache" at the start of each collection
    machines = 0

    Machine.where(status: 'poweredOn', is_pod_container: true).each do |machine|
      begin
        machines += 1
        reading_at, pod_summary = get_pod_usage(machine)

        if pod_summary
          $logger.debug { "Saving disk usage for #{machine.name}@#{reading_at}: #{pod_summary['usage_bytes']}" }
          machine.disks.first.disk_samples.create!(reading_at: reading_at, usage_bytes: pod_summary['usage_bytes'])

          previous = NicSample.where(machine_custom_id: machine.custom_id).order_by(reading_at: :desc).first
          # TODO this algorithm should be in the code below as well? (i.e., cpu, disk_io)
          if previous
            duration = reading_at - previous.reading_at
            next if duration == 0
            transmit_rate = (pod_summary['network_tx'] - previous.network_tx).to_f / duration
            receive_rate = (pod_summary['network_rx'] - previous.network_rx).to_f / duration
            machine.nics.first.nic_samples.create!(machine_custom_id: machine.custom_id,
                                                   reading_at: reading_at,
                                                   network_tx: pod_summary['network_tx'],
                                                   network_rx: pod_summary['network_rx'],
                                                   transmit_bytes_per_second: transmit_rate,
                                                   receive_bytes_per_second: receive_rate)
          else
            # else - since we want a rate, we can't do anything until we have at least 1 prior sample
            machine.nics.first.nic_samples.create!(machine_custom_id: machine.custom_id,
                                                   reading_at: reading_at,
                                                   network_tx: pod_summary['network_tx'],
                                                   network_rx: pod_summary['network_rx'])
          end

          # The OnPrem connector code does a MachineSamples.where... so we need to create a dummy sample for the above samples to get picked up
          machine_sample = machine.machine_samples.create!(reading_at: reading_at)
        else
          $logger.warn { "pod summary is null for #{machine.name}" }
        end
      rescue => e
        # E11000=duplicate key error, which is OK, since duplicate readings are expected with cadvisor
        e.message.start_with?('E11000') ?
          $logger.debug { "#{e.message} raised for #{machine.name} sample at #{current_sample['timestamp']}" } :
          $logger.warn { "#{e.message} raised for #{machine.name} sample at #{current_sample['timestamp']}" }
      end
    end
    $logger.debug { "Metered summaries for #{machines} infrastructure pods" }
  end

  def collect_container_stats
    begin
      $logger.info { 'Collecting container metrics for the cluster' }
      metered_machines = 0

      Machine.where(status: 'poweredOn', is_pod_container: false).each do |machine|
        metered_machines += 1
        $logger.debug { "Collecting container metrics for #{machine.name} container..." }

        # begin/rescue for 404s?
        metrics = KubeletAPI::stats(@config, machine)
        previous_sample = nil

        samples = metrics['stats']
        $logger.debug { "Raw 'stats' for #{machine.name}: #{samples}" } if ENV['DUMP_RAW_STATS']

        samples.each do |sample|
          current_sample = parse_sample(sample)
          if previous_sample
            begin
              current_cpu_usage  = Integer(current_sample['cpu_usage'])
              previous_cpu_usage = Integer(previous_sample['cpu_usage'])
              if current_cpu_usage >= previous_cpu_usage
                duration = current_sample['timestamp'].to_time - previous_sample['timestamp'].to_time

                # Collect Machine Sample
                machine_sample = machine.machine_samples.new(reading_at: current_sample['timestamp'])
                machine_sample.cpu_usage_percent = (current_cpu_usage - previous_cpu_usage) / 1_000_000_000.0 / machine.cpu_count * 100  # usage is returned by the API in nanocores, so we divided by a billion
                machine_sample.memory_bytes = current_sample['memory_bytes']
                machine_sample.save!

                # Collect Disk Sample
                disk_sample = machine.disks.first.disk_samples.new(reading_at: current_sample['timestamp'])
                disk_sample.reading_at = current_sample['timestamp']

                disk_sample.read_bytes_per_second = ((current_sample['diskio_bytes_read'] - previous_sample['diskio_bytes_read']).to_f / duration).round
                disk_sample.write_bytes_per_second = ((current_sample['diskio_bytes_write'] - previous_sample['diskio_bytes_write']).to_f / duration).round

                #disk_sample.usage_bytes = current_sample['storage_bytes']
                disk_sample.save!

              end
              # else, if current_cpu_usage < previous_cpu_usage, fall through and set previous=current; but don't create a sample for this time period (likely a container start/restart)
            rescue => e
              # E11000=duplicate key error, which is OK, since duplicate readings are expected with cadvisor
              e.message.start_with?('E11000') ?
                $logger.debug { "#{e.message} raised for #{machine.name} sample at #{current_sample['timestamp']}" } :
                $logger.warn { "#{e.message} raised for #{machine.name} sample at #{current_sample['timestamp']}" }
            end
          end
          previous_sample = current_sample
        end if samples

        $logger.debug { "Collected metrics for #{machine.name} successfully." }
      end

      if metered_machines > 0
        $logger.info { "Total machines metered in this run: #{metered_machines}" }
      else
        $logger.debug { 'Found no machines to be metered. Waiting for the next run.' }
      end

    rescue => e
      $logger.warn { "Unable to retrieve container stats: #{e.message}" }
      $logger.debug { e.backtrace.join("\n") }
    end
  end

  def parse_sample(sample)
    extracted_sample = {}
    
    # Initialize variable
    extracted_sample['timestamp'] = sample['timestamp']
    extracted_sample['cpu_usage'] = 0
    extracted_sample['memory_bytes'] = 0
    extracted_sample['storage_bytes'] = 0
    extracted_sample['diskio_bytes_read'] = 0
    extracted_sample['diskio_bytes_write'] = 0
    extracted_sample['network_bytes_receive'] = 0
    extracted_sample['network_bytes_transmit'] = 0
    
    # Extract sample details
    unless sample['cpu'].empty?
      extracted_sample['cpu_usage'] = sample['cpu']['usage']['total']
    end
    unless sample['memory'].empty?
      extracted_sample['memory_bytes'] = sample['memory']['usage']
    end
    unless sample["filesystem"].empty?
      extracted_sample['storage_bytes'] = sample["filesystem"][0]["usage"]
    end
    unless sample['diskio'].empty?
      extracted_sample['diskio_bytes_read'] = sample['diskio']['io_service_bytes'].map{|io| io['stats']['Read']}.sum
      extracted_sample['diskio_bytes_write'] = sample['diskio']['io_service_bytes'].map{|io| io['stats']['Write']}.sum
    end
    unless sample['network'].empty?
      extracted_sample['network_bytes_receive'] = sample['network']['rx_bytes']
      extracted_sample['network_bytes_transmit'] = sample['network']['tx_bytes']
    end
    
    extracted_sample
  end

  def get_pod_usage(machine)
    if @summary_stats.has_key?(machine.host_ip)
      #  FIXME need to handle missing pod?
      $logger.warn "Missing pod data for #{machine.name}/#{machine.pod_uid}"  unless @summary_stats[machine.host_ip].has_key?(machine.pod_uid)
      [ @summary_stats[machine.host_ip]['reading_at'], @summary_stats[machine.host_ip][machine.pod_uid] ]
    else
      summary_metrics = KubeletAPI::summary(@config, machine)
      $logger.debug { "#{machine.host_ip}: pods missing volumes: " +
                      summary_metrics['pods']
                        .reject{|pod| pod['volume']}
                        .map{|pod| "#{pod['podRef']['namespace']}:#{pod['podRef']['name']}:#{pod['containers']&.map{|c|c['name']}&.join('|')}"}.join(',') }

      # The volumes data structure, from cadvisor, doesn't include a timestamp, so we're left to assume the data is current
      #  Note: it does include a "time" field. This seems to correlate to volume create time
      @summary_stats[machine.host_ip]['reading_at'] = Time.now
      # Convert the summary JSON into: hash[ip][pod uid] = sum of all volumes on pod
      summary_metrics['pods'].map do |pod|
        summaries = {}
        summaries['usage_bytes'] = pod['volume']&.sum{|v| v['usedBytes']} || 0
        summaries['network_rx'] = pod['network']&.dig('rxBytes') || 0
        summaries['network_tx'] = pod['network']&.dig('txBytes') || 0
        @summary_stats[machine.host_ip][pod['podRef']['uid']] = summaries
      end
      [ @summary_stats[machine.host_ip]['reading_at'], @summary_stats[machine.host_ip][machine.pod_uid] ]
    end
  end


end
