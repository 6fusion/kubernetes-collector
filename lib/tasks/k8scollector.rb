#!/usr/bin/env ruby
require './config/defaults'

# Initialize the application logger
logger = K8scollector::init_logger

logger.info 'Initializing Kubernetes collector...'

begin
  # Initialize MongoDB connection
  K8scollector::init_mongodb(logger)

  # Load configuration values
  config = K8scollector::load_configuration(logger)

  # If we hit a 5 minute interval, submit the samples to the On Premise API
  # Initialize On-Premise connector
  OnPremiseConnector.new(logger, config).sync if Time.now.utc.min % 5 == 0

  # Collect the inventory
  InventoryCollector.new.collect(logger, config)

  # Collect the metrics
  MetricsCollector.new.collect(logger, config)
rescue Exception => e
  logger.error e
  logger.error 'Kubernetes collector aborted'
end
