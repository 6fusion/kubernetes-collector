require 'mongoid'
require 'rest-client'
require 'clockwork'
Dir.glob("./app/**/*.rb").each {|file| require file}

SECRETS_DIR = '/var/run/secrets/k8scollector'
ONPREMISE_API_VERSION = 'v1'
ON_PREMISE_SCHEDULER_PERIOD = 55.seconds

include OnPremise
include OnPremiseApi
include Exceptions
include Clockwork
