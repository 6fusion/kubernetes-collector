#!/usr/bin/env ruby
require_relative '../config/defaults'

Thread.abort_on_exception = true

$logger.info 'Initializing Kubernetes Meter Submission Handler'

# Load configuration values
config = Inventory::load_configuration($logger)

connector = OnPremiseConnector.new(config)

loop {
  connector.sync
  $logger.info 'On-Premise connector finished successfully'
  sleep 1.second }
