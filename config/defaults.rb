require 'mongoid'
require 'rest-client'
Dir.glob("./app/**/*.rb").each {|file| require file}

SECRETS_DIR = '/var/run/secrets/k8scollector'
KUBE_API_VERSION = 'v1'
CADVISOR_API_VERSION = 'v2.0'

include K8scollector
include OnPremiseApi