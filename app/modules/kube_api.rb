module KubeAPI

  def self.request(config, endpoint, method=:get)
    response = RestClient::Request.execute(:method => method, :url => "#{config.kube[:url]}/#{endpoint}", :headers => config.kube[:headers], :verify_ssl => config.kube[:verify_ssl])
    JSON.parse(response.body)
  end

end