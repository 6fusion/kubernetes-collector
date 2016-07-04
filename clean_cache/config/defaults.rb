require 'mongoid'
require 'rest-client'
require 'clockwork'
Dir.glob("./app/**/*.rb").each {|file| require file}

DATA_AGE_PERIOD = 20.minutes
CLEAN_CACHE_SCHEDULER_PERIOD = 15.minutes

include CleanCache
include CleanCacheData
include Clockwork
