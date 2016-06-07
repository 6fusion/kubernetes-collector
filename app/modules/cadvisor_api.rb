# This class is responsible for making the requests to the cAdvisor API
module CAdvisorAPI

  def self.request(config, host, endpoint)
    begin
      response = RestClient::Request.execute(:method => :get, :url => "#{config.kube[:cadvisor_protocol]}://#{host}:#{config.kube[:cadvisor_port]}/api/#{CADVISOR_API_VERSION}/#{endpoint}")
      JSON.parse(response.body)
    rescue Exception => e
      Logger.new(STDOUT).error "Operational error with the cAdvisor API at #{config.kube[:cadvisor_protocol]}://#{host}:#{config.kube[:cadvisor_port]}. See error details below:"
      raise Exception.new(e.message)
    end
  end

end