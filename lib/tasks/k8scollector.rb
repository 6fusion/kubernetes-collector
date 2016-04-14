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

  puts config.inspect
rescue Exception => e
  logger.error e
  logger.error 'Kubernetes collector aborted'
end
