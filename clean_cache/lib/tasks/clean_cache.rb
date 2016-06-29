#!/usr/bin/env ruby
require './config/defaults'

begin
  # Initialize the application logger
  logger = CleanCache::init_logger
  logger.info 'Initializing Clean Cache db...'

  # Initialize MongoDB connection
  CleanCache::init_mongodb(logger)

  # Define the clean cache db scheduled job    
  handler do |job|
    if job.eql?('clean-cache.connect')
      begin
        # Initialize Clean Cache db
        remove_old_data(logger)
        logger.info 'Clean cache db finished successfully...'
      rescue Exception => e
        logger.error e
        logger.error 'Clean cache db process couldn\'t finish. Waiting for the next run...'
      end
    end
  end

  # Schedule the clean cache db job
  every(CLEAN_CACHE_SCHEDULER_PERIOD, 'clean-cache.connect', :thread => true)
rescue Exception => e
  logger.error e
  logger.error 'Clean Cache db process aborted'
end
