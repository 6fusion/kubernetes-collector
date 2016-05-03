require 'mongoid'
require 'rest-client'
Dir.glob("./app/**/*.rb").each {|file| require file}

SECRETS_DIR = '/var/run/secrets/k8scollector'
KUBE_API_VERSION = 'v1'
CADVISOR_API_VERSION = 'v2.0'
CADVISOR_SAMPLES_COUNT = 15
ONPREMISE_API_VERSION = 'v1'
DATA_AGE_PERIOD = 1.day

include K8scollector
include KubeAPI
include CAdvisorAPI
include OnPremiseApi
include CleanCacheData
