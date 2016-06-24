require 'mongoid'
require 'rest-client'
require 'clockwork'
require 'open3'

METRICS_SCHEDULER_PERIOD = 1.second
SECRETS_DIR = '/var/run/secrets/k8scollector'
CADVISOR_API_VERSION = 'v2.0'
CADVISOR_SAMPLES_COUNT = 15
METERING_TIMEOUT = 15.seconds
MACHINES_LIMIT = 10

Dir.glob("./app/**/*.rb").each {|file| require file}

include Clockwork
include Metrics
include CAdvisorAPI
include Exceptions
