#!/usr/bin/env ruby
require_relative '../config/defaults'

Thread.abort_on_exception = true
$logger.info 'Initializing Kubernetes Metrics Collector'

config = Inventory::load_configuration($logger)

collector = MetricsCollector.new(config)
collection_interval = ENV['METRICS_COLLECTION_INTERVAL']&.to_i || 30

$logger.info { "OpenShift metrics collector initialized to meter every #{collection_interval} seconds" }

t1 = Thread.new {
  loop {
    collector.collect_container_stats
    sleep(collection_interval) } }

t2 = Thread.new {
  loop {
    collector.collect_pod_summaries
    sleep(collection_interval) } }

t1.join