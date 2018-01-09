# This class is responsible for making the requests to the 6fusion meter
# On Premise API
module OnPremiseApi
  def request_api(endpoint, method, config, parameters = nil)
    begin
      token_param = config.on_premise[:token].empty? ? '' : "?access_token=#{config.on_premise[:token]}"
      response = RestClient::Request.execute(url: "#{config.on_premise[:url]}/#{endpoint}#{token_param}",
                                             method: method,
                                             payload: parameters.to_json,
                                             headers: { accept: :json, content_type: :json },
                                             verify_ssl: config.on_premise[:verify_ssl])
      JSON.parse(response.body)
    rescue Exception => e
      $logger.error { e }
      $logger.debug { "payload: #{parameters.to_json}" }
      raise e
    end
  end
end
