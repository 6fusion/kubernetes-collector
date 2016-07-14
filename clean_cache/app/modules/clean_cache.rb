# This class is responsible for initializing the clean cache values required
# to carry out the whole process
module CleanCache
  def init_logger
    logger = Logger.new(STDOUT)
    logger.level = Logger::DEBUG
    logger
  end

  def init_mongodb(logger)
    logger.info 'Loading MongoDB configuration...'
    Mongoid.load! 'config/mongoid.yml'
  end

  def load_configuration(logger)
    logger.info 'Loading clean cache configuration values...'
    CleanCacheConfig.new
  end
end
