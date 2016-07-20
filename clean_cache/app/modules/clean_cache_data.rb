# This class is responsible for cleaning data from the MongoDB cache older than
# the value set by DATA_AGE_PERIOD
module CleanCacheData
  def remove_old_data(config, logger)
    reset_statistics

    current_time = Time.now.utc
    @age_time = current_time - config.on_premise[:data_age_period]

    logger.info "Cleaning data older than #{@age_time} from the cache db..."
    remove_old_samples
    remove_structures_without_samples(logger)
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

  def remove_structures_without_samples(logger)
    logger.info 'Removing machines (their disks and nics too) without samples for the last period...'
    Machine.all.each do |machine|
      remove_structures(machine) if old_machine?(machine)
    end
  end

  def old_machine?(machine)
    machine.status == Machine::STATUS_POWERED_OFF && machine.machine_samples.blank? 
  end

  def remove_structures(machine)
    @deleted_disks += machine.disks.destroy_all
    @deleted_nics += machine.nics.destroy_all
    machine.destroy
    @deleted_machines += 1
  end

  def statistics_report(logger)
    logger.info "Deleted #{@deleted_samples} samples."
    logger.info "Deleted #{@deleted_machines} machines."
    logger.info "Deleted #{@deleted_nics} nics."
    logger.info "Deleted #{@deleted_disks} disks."
  end
end
