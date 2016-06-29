#!/usr/bin/env ruby
require './config/defaults'

# Initialize the application logger
logger = Inventory::init_logger

logger.info 'Initializing Kubernetes Inventory collector...'

begin
  # Initialize MongoDB connection
  Inventory::init_mongodb(logger)

  # Load configuration values
  config = Inventory::load_configuration(logger)

  logger.info 'Kubernetes Inventory collector initialized successfully...'
  logger.info 'Collecting inventory...'

  # Define the inventory collector scheduled job
  handler do |job|
    if job.eql?('inventory.collect')
      begin
        # Collect the inventory
        InventoryCollector.new(logger, config).collect
        logger.info 'Inventory collected successfully...'
      rescue Exception => e
        logger.error e
        logger.error 'Inventory collection process couldn\'t finish. Waiting for the next run...'
      end
    end
  end

  # Schedule the inventory collector job
  every(INVENTORY_SCHEDULER_PERIOD, 'inventory.collect', :thread => true)
rescue Exception => e
  logger.error e
  logger.error 'Kubernetes Inventory collector aborted. Please check the configuration values.'
end
