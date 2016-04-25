module OnPremiseApi

  def request_api(endpoint, method, config, parameters=nil)
    response = RestClient::Request.execute(:url => "#{config.on_premise[:url]}/#{endpoint}", :method => method,
                                           :payload => parameters, accept: :json, content_type: :json)
    JSON.parse(response.body)
  end

end