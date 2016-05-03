module CleanCacheData

  def remove_old_data(logger)
  	reset_statistics

  	current_time = Time.now.utc
    @end_time = current_time 
    @start_time = current_time - DATA_AGE_PERIOD

    logger.info 'Removing old samples for the last period...'
  	remove_old_samples
  	remove_structures_without_samples(logger)
  	statistics_report(logger)
  	logger.info 'Cleaning temporary data completed successfully.'
  end

  def reset_statistics
    @deleted_samples = 0
    @deleted_machines = 0
    @deleted_nics = 0
    @deleted_disks = 0
  end

  def remove_old_samples
  	machine_sample_count = MachineSample.destroy_all(reading_at: (@start_time..@end_time))
  	nic_sample_count = NicSample.destroy_all(reading_at: (@start_time..@end_time))
  	disk_sample_count = DiskSample.destroy_all(reading_at: (@start_time..@end_time))
  	@deleted_samples = machine_sample_count + nic_sample_count + disk_sample_count
  end

  def remove_structures_without_samples(logger)
  	logger.info 'Removing machines without samples for the last period...'
  	@deleted_machines = Machine.all.map { |machine| machine.destroy if machine.machine_samples.blank? }
  	
  	logger.info 'Removing nics without samples for the last period...'
  	@deleted_nics = Nic.all.map { |nic| nic.destroy if nic.nic_samples.blank? }
  	
  	logger.info 'Removing disks without samples for the last period...'
  	@deleted_disks = Disk.all.map { |disk| disk.destroy if disk.disk_samples.blank? }
  end

  def statistics_report(logger)
    logger.info "Deleted #{@deleted_samples} samples."
    logger.info "Deleted #{@deleted_machines} machines."
    logger.info "Deleted #{@deleted_nics} nics."
    logger.info "Deleted #{@deleted_disks} disks."
  end
end