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

  def verify_organization(logger, config)
    logger.info 'Verifying current organization in the On Premise API...'
    begin
      # Verify that the Organization exists in the On Premise API. Otherwise, raise an exception.
      endpoint = "organizations/#{config.on_premise[:organization_id]}"
      response = RestClient::Request.execute(url: "#{config.on_premise[:url]}/#{endpoint}",
                                             method: :get,
                                             accept: :json, content_type: :json,
                                             verify_ssl: config.on_premise[:verify_ssl],
                                             headers: { 'Authorization': "Bearer #{config.on_premise[:token]}" } )
    rescue Exception => e
      logger.error "Could not verify the organization with ID=#{config.on_premise[:organization_id]}"
      raise Exceptions::CollectorException, e.message
    end
  end

end
