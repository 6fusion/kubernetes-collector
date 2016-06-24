#!/usr/bin/env ruby
require './config/defaults'

# Initialize the application logger
logger = Metrics::init_logger

logger.info 'Initializing Kubernetes Metrics collector...'

begin
  # Initialize MongoDB connection
  Metrics::init_mongodb(logger)

  # Load configuration values
  config = Metrics::load_configuration(logger)

  logger.info 'Kubernetes Metrics collector initialized successfully...'
  logger.info 'Collecting metrics...'

  # Define the metrics collector scheduled job
  handler do |job|
    if job.eql?('metrics.collect')
      begin
        # Collect the metrics
        MetricsCollector.new(logger, config).collect
        logger.info 'Metrics collection process finished successfully...'
      rescue Exception => e
        logger.error e
        logger.error 'Metrics collection process couldn\'t finish. Waiting for the next run...'
      end
    end
  end

  # Schedule the inventory collector job
  every(METRICS_SCHEDULER_PERIOD, 'metrics.collect')
rescue Exception => e
  logger.error e
  logger.error 'Kubernetes Metrics collector aborted. Please check the configuration values.'
end
