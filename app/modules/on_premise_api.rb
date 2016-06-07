module OnPremiseApi

  def request_api(endpoint, method, config, parameters=nil)
    begin
    	if method == :get
    	  response = RestClient::Request.execute(url: "#{config.on_premise[:url]}/#{endpoint}", method: method,
    	  										 payload: parameters.to_json, accept: :json, content_type: :json)
    	else
    	  response = RestClient.send(method, "#{config.on_premise[:url]}/#{endpoint}", parameters.to_json, accept: :json, content_type: :json)
    	end
    	JSON.parse(response.body)
    rescue Exception => e
      Logger.new(STDOUT).error "Operational error with the 6fusion meter API at #{config.on_premise[:url]}. See error details below:"
      raise Exception.new(e.message)
    end
  end

end