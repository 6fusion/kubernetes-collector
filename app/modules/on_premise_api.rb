module OnPremApi

  def request_api(endpoint, method, config, parameters=nil)
  	RestClient::Request.execute(:url => "#{config.on_premise[:url]}/#{endpoint}", :method => method, 
  								:payload => parameters, accept: :json, content_type: :json)
  end
  
end