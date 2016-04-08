require 'mongoid'
require './app/modules/k8scollector'

SECRETS_DIR = '/var/run/secrets/k8scollector'

include K8scollector