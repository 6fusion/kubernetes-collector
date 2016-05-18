module KubeAPI

  def self.request(config, endpoint, method=:get)
    begin
      response = RestClient::Request.execute(:method => method, :url => "#{config.kube[:url]}/#{endpoint}", :headers => config.kube[:headers], :verify_ssl => config.kube[:verify_ssl])
      JSON.parse(response.body)
    rescue Exception => e
      Logger.new(STDOUT).error 'Operational error with the Kubernetes API. See error details below:'
      raise Exception.new(e.message)
    end
  end

end