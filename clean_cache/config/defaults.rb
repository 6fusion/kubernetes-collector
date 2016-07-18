require 'mongoid'
require 'rest-client'
require 'clockwork'
Dir.glob("./app/**/*.rb").each {|file| require file}

SECRETS_DIR = '/var/run/secrets/k8scollector'
DATA_AGE_PERIOD_DEFAULT = 20
CLEAN_CACHE_SCHEDULER_PERIOD = 15.minutes

include CleanCache
include CleanCacheData
include Clockwork
