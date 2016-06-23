# This class is responsible for initializing the inventory collector values required
# to carry out the whole process
module Inventory

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
    logger.info 'Loading inventory collector configuration values...'
    InventoryConfig.new
  end

end
