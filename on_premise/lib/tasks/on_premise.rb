#!/usr/bin/env ruby
require './config/defaults'

begin
  # Initialize the application logger
  logger = OnPremise::init_logger
  logger.info 'Initializing On-Premise connector...'

  # Initialize MongoDB connection
  OnPremise::init_mongodb(logger)

  # Load configuration values
  config = OnPremise::load_configuration(logger)

  # Define the on-premise connector scheduled job 	 
  handler do |job|
  	if job.eql?('on-premise.connect')
  	  begin
  	  	# Initialize On-Premise connector
    	OnPremiseConnector.new(logger, config).sync 
    	logger.info 'On-Premise connector finished successfully...'
  	  rescue
  	  	logger.error e
        logger.error 'On-Premise connector process couldn\'t finish. Waiting for the next run...'
  	  end
  	end
  end

  # If we hit a 5 minute interval, submit the samples to the On Premise API
  every(ON_PREMISE_SCHEDULER_PERIOD, 'on-premise.connect', :thread => true, :if => lambda { |t| t.min % 5 == 0 })
rescue Exception => e
  logger.error e
  logger.error 'On-Premise connector process aborted'
end
