module CAdvisorAPI

  def self.request(config, host, endpoint)
    response = RestClient::Request.execute(:method => :get, :url => "#{config.kube[:cadvisor_protocol]}://#{host}:#{config.kube[:cadvisor_port]}/api/#{CADVISOR_API_VERSION}/#{endpoint}")
    JSON.parse(response.body)
  end

end