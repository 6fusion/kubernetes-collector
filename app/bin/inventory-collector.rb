#!/usr/bin/env ruby
require_relative '../config/defaults'

$logger.info 'Initializing Kubernetes Inventory Collector'

# Load configuration values
config = Inventory::load_configuration($logger)

# Verify that the Organization exists in the On Premise API
Inventory::verify_organization($logger, config)

begin
  while true
    InventoryCollector.new(config).collect
    $logger.info 'Inventory collected successfully...'
    sleep INVENTORY_SCHEDULER_PERIOD
  end
rescue Exception => e
  $logger.error e
  raise e
end
