require 'mongoid'
require 'rest-client'
require 'clockwork'
Dir.glob("./app/**/*.rb").each {|file| require file}

INVENTORY_SCHEDULER_PERIOD = 30.seconds
KUBE_TOKEN_LOCATION = '/var/run/secrets/kubernetes.io/serviceaccount/token'
SECRETS_DIR = '/var/run/secrets/k8scollector'
KUBE_API_VERSION = 'v1'
CADVISOR_API_VERSION = 'v2.0'
ONPREMISE_API_VERSION = 'v1'
METERING_TIMEOUT = 30.seconds

include Clockwork
include Inventory
include KubeAPI
include CAdvisorAPI
include OnPremiseApi
include Exceptions
