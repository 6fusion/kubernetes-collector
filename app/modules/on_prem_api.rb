module OnPremApi

  def request_api(endpoint, method, parameters, config)
  	RestClient::Request.execute(:url => "#{config.kube[:url]}/#{endpoint}", 
  								:method => method, :payload => parameters, accept: :json, content_type: :json)
  end
  
end