require 'mongoid'
require 'pathname'
require 'rest-client'
require 'pry'

app_dir = Pathname.new(__FILE__).parent.parent
Dir.glob("#{app_dir}/models/*.rb").each {|file| require file}
Dir.glob("#{app_dir}/modules/*.rb").each{|file| require file}
Dir.glob("#{app_dir}/collectors/*.rb").each{|file| require file}

INVENTORY_SCHEDULER_PERIOD = 30.seconds
KUBE_API_VERSION = 'v1'
CADVISOR_API_VERSION = 'v2.0'
ONPREMISE_API_VERSION = 'v1'
METERING_TIMEOUT = 30.seconds

include Inventory
include KubeAPI
include KubeletAPI
include CAdvisorAPI
include OnPremiseApi
include Exceptions

namespace = File.readable?('/var/run/secrets/kubernetes.io/serviceaccount/namespace') ? File.read('/var/run/secrets/kubernetes.io/serviceaccount/namespace') : '6fusion-kubernetes-collector'

Mongoid::Config.load_configuration({clients: {default: {
                                                 database: '6fusion',
                                                 hosts:   [ "mongo.#{namespace}.svc.cluster.local:27017" ] } } })

$logger = Logger.new(STDOUT)
$logger.level = ENV['LOG_LEVEL'] || Logger::INFO
