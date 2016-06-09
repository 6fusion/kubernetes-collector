# This class is responsible for cleaning data from the MongoDB cache older than the value set by DATA_AGE_PERIOD
module CleanCacheData

  def remove_old_data(logger, config)
  	reset_statistics

  	current_time = Time.now.utc
    @age_time = current_time - DATA_AGE_PERIOD

    logger.info "Cleaning data older than #{@age_time} from the cache db..."
  	remove_old_samples
  	remove_structures_without_samples(logger, config)
  	statistics_report(logger)
  	logger.info 'Cleaning old data completed successfully.'
  end

  def reset_statistics
    @deleted_samples = 0
    @deleted_machines = 0
    @deleted_nics = 0
    @deleted_disks = 0
  end

  def remove_old_samples
  	machine_sample_count = MachineSample.destroy_all(:reading_at.lte => @age_time)
  	nic_sample_count = NicSample.destroy_all(:reading_at.lte => @age_time)
  	disk_sample_count = DiskSample.destroy_all(:reading_at.lte => @age_time)
  	@deleted_samples = machine_sample_count + nic_sample_count + disk_sample_count
  end

  def remove_structures_without_samples(logger, config)
  	logger.info 'Removing machines (their disks and nics too) without samples for the last period...'
  	Machine.all.each do |machine|
      if machine.machine_samples.blank?
        @deleted_disks += machine.disks.destroy_all
        @deleted_nics += machine.nics.destroy_all
        # Before destroying the machine, update its status to poweredOff on the on premise API if it exists there
        if machine.remote_id
          machine.status = 'poweredOff'
          endpoint = "machines/#{machine.remote_id}"
          payload = machine.to_payload
          OnPremiseApi::request_api(endpoint, :put, config, payload)
        end
        # Destroy the machine
        machine.destroy
        @deleted_machines += 1
      end
    end
  end

  def statistics_report(logger)
    logger.info "Deleted #{@deleted_samples} samples."
    logger.info "Deleted #{@deleted_machines} machines."
    logger.info "Deleted #{@deleted_nics} nics."
    logger.info "Deleted #{@deleted_disks} disks."
  end
end