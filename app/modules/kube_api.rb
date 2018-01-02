# This module is responsible for making the requests to the Kubernetes API
module KubeAPI
  def self.services(config, namespace)
    begin
      url = "#{config.kube[:url]}/namespaces/#{namespace['metadata']['name']}/services"
      response = RestClient::Request.execute(:url => url, :method => :get, :headers => config.kube[:headers], :verify_ssl => config.kube[:verify_ssl])
      JSON.parse(response.body)
    rescue => e
      Logger.new(STDOUT).error "Error occurred retrieving services via the Kubernetes API at #{url}. See error details below:"
      message = e.message
      raise Exceptions::CollectorException, message
    end
  end

  def self.endpoints(config)
    begin
      url = "#{config.kube[:url]}/endpoints"
      response = RestClient::Request.execute(:url => url, :method => :get, :headers => config.kube[:headers], :verify_ssl => config.kube[:verify_ssl])
      JSON.parse(response.body)
    rescue => e
      Logger.new(STDOUT).error "Error occurred retrieving services via the Kubernetes API at #{url}. See error details below:"
      message = e.message
      raise Exceptions::CollectorException, message
    end
  end

  def self.pods(config, namespace, service=nil)
    begin
      url = if service
              label_selector = ''
              service['spec']['selector'].each {|k, v| label_selector << "#{k}=#{v},"}
              label_selector = label_selector.to_s.chop  # Remove the last comma from the label selector
              "#{config.kube[:url]}/namespaces/#{namespace['metadata']['name']}/pods?labelSelector=#{label_selector}"
            else
              "#{config.kube[:url]}/namespaces/#{namespace['metadata']['name']}/pods"
            end
      response = RestClient::Request.execute(url: url, method: :get, headers: config.kube[:headers], verify_ssl: config.kube[:verify_ssl])
      JSON.parse(response.body)
    rescue => e
      Logger.new(STDOUT).error "Error occurred retrieving pods via the Kubernetes API at #{url}. See error details below:"
      message = e.message
      raise Exceptions::CollectorException, message
    end
  end

  def self.pod_status(config, pod)
    begin
      url = "#{config.kube[:url]}/namespaces/#{pod.namespace}/pods/#{pod.name}"
      response = RestClient::Request.execute(url: url, method: :get, headers: config.kube[:headers], verify_ssl: config.kube[:verify_ssl])
      JSON.parse(response.body)['status']
    rescue => e
      Logger.new(STDOUT).error "Error occurred retrieving pods via the Kubernetes API at #{url}. See error details below:"
      message = e.message
      raise Exceptions::CollectorException, message
    end
  end

  def self.nodes(config)
    begin
      url = "#{config.kube[:url]}/nodes"
      response = RestClient::Request.execute(:url => url, :method => :get, :headers => config.kube[:headers], :verify_ssl => config.kube[:verify_ssl])
      JSON.parse(response.body)
    rescue => e
      Logger.new(STDOUT).error "Error occurred retrieving nodes via the Kubernetes API at #{url}. See error details below:"
      message = e.message
      raise Exceptions::CollectorException, message
    end
  end
  def self.node(config, node)
    begin
      url = "#{config.kube[:url]}/nodes/#{node}"
      response = RestClient::Request.execute(:url => url, :method => :get, :headers => config.kube[:headers], :verify_ssl => config.kube[:verify_ssl])
      JSON.parse(response.body)
    rescue => e
      Logger.new(STDOUT).error "Error occurred retrieving nodes via the Kubernetes API at #{url}. See error details below:"
      message = e.message
      raise Exceptions::CollectorException, message
    end
  end

  def self.request(config, endpoint, method = :get)
    begin
      response = RestClient::Request.execute(method: method, url: "#{config.kube[:url]}/#{endpoint}",
                                             headers: config.kube[:headers],
                                             verify_ssl: config.kube[:verify_ssl])
      JSON.parse(response.body)
    rescue Exception => e
      Logger.new(STDOUT).error "Operational error with the Kubernetes API at #{config.kube[:url]}. See error details below:"
      message = e.message
      raise Exceptions::CollectorException, message
    end
  end

  def self.namespaces(config)
    begin
      url = "#{config.kube[:url]}/namespaces"
      response = RestClient::Request.execute(:url => url, :method => :get, :headers => config.kube[:headers], :verify_ssl => config.kube[:verify_ssl])

      Logger.new(STDOUT).debug "Namespaces response: #{response.code}"
      Logger.new(STDOUT).debug "Namespaces response: #{response.body}"

      JSON.parse(response.body)
    rescue => e
      Logger.new(STDOUT).error "Error occurred retrieving namespaces via the Kubernetes API at #{url}. See error details below:"
      message = e.message
      raise Exceptions::CollectorException, message
    end
  end


end
