module OnPremiseApi

  def request_api(endpoint, method, config, parameters=nil)
  	if method == :get
  	  response = RestClient::Request.execute(url: "#{config.on_premise[:url]}/#{endpoint}", method: method, 
  	  										 payload: parameters.to_json, accept: :json, content_type: :json) 
  	else
  	  response = RestClient.send(method, "#{config.on_premise[:url]}/#{endpoint}", parameters.to_json, accept: :json, content_type: :json)
  	end
  	JSON.parse(response.body)
  end

end