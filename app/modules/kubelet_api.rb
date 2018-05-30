# This class is responsible for making the requests to the kubelet (cadvisor) API
module KubeletAPI
  def self.node_attributes(config, host)
    begin
      url = "#{config.kubelet[:protocol]}://#{host}:#{config.kubelet[:port]}/spec/"
      response = RestClient::Request.execute(url: url, method: :get, headers: config.kube[:headers], verify_ssl: config.kube[:verify_ssl], open_timeout: 5)
      JSON.parse(response.body)
    rescue e
      Logger.new(STDOUT).error "Error occurred retrieving node attributes via the kubelet API at #{url}. See error details below:"
      message = e.message
      raise Exceptions::CollectorException, message
    end
  end

  def self.container_attributes(config, host)
    begin
      url = "#{config.kubelet[:protocol]}://#{host}:#{config.kubelet[:port]}/stats/container"
      payload = {containerName: "#{config.kubelet[:cgroup_namespace]}", subcontainers: true, num_stats: 1}.to_json
      response = RestClient::Request.execute(url: url, method: :post, headers: config.kube[:headers], verify_ssl: config.kube[:verify_ssl], open_timeout: 5, :payload => payload, accept: :json, content_type: :json)
      JSON.parse(response.body)
    rescue => e
      Logger.new(STDOUT).error "Error occurred retrieving container attributes via the kubelet API #{url}. See error details below:"
      message = e.message
      raise Exceptions::CollectorException, message
    end
  end

  def self.stats(config, machine)
    url = "#{config.kubelet[:protocol]}://#{machine.host_ip}:#{config.kubelet[:port]}/stats/" \
          "#{machine.namespace}/#{machine.pod_name}/#{machine.pod_uid}/#{machine.container_name}"
    begin
      response = RestClient::Request.execute(url: url, method: :get, headers: config.kube[:headers], verify_ssl: config.kube[:verify_ssl], open_timeout: 5, accept: :json, content_type: :json)
      JSON.parse(response.body)
    rescue => e
      Logger.new(STDOUT).debug { "Query URL: #{url} " }
      raise Exceptions::CollectorException, e.message
    end
  end

  # Data currently interested in:
  # .pods[].uid
  #        .name
  #        .namespace
  #        .volume[].time
  #                 .usedBytes
  #                 .name?
  #        .network.time
  #                .rxBytes
  #                .txBytes
  def self.summary(config, machine)
    url = "#{config.kubelet[:protocol]}://#{machine.host_ip}:#{config.kubelet[:port]}/stats/summary"
    begin
      response = RestClient::Request.execute(url: url, method: :get, headers: config.kube[:headers], verify_ssl: config.kube[:verify_ssl], open_timeout: 5, accept: :json, content_type: :json)
      JSON.parse(response.body)
    rescue => e
      l = Logger.new(STDOUT)
      l.error { "Error retrieving summary stats: #{e.message}" }
      l.debug { "Query URL: #{url} " }
      l.debug { e.backtrace.join("\n") }
      raise Exceptions::CollectorException, e.message
    end
  end
  
  def self.logs(config, pod)
    puts pod.container_name
    binding.pry
    url = "#{config.kube[:url]}/namespaces/#{pod.namespace}/pods/#{pod.pod_name}/log?container=#{pod.container_name}"
   # puts url
  #  binding.pry
    begin
      response = RestClient::Request.execute(url: url, method: :get, headers: config.kube[:headers], verify_ssl: config.kube[:verify_ssl], open_timeout: 5)
     # RestClient.log = 'stdout'
      #puts response.inspect
     # binding.pry
      l = Logger.new(STDOUT)
     #l.debug {JSON.generate(response.body.split("\n").each_slice(1).map{|s| {message:s[0]}})}
      response.body    
     #JSON.generate(response.body.split("\n").each_slice(1).map{|s| {message:s[0]}})
      #l.debug {JSON.generate(response.body)}
      #binding.pry
      #response.body.split("\n") #['status']
      #split("\n")
    rescue => e
      l = Logger.new(STDOUT)
      l.error "Error occurred retrieving pods via the Kubernetes API at #{url}. See error details below:"
      message = e.message
      l.debug { "Query URL: #{url} " }
      l.debug { e.backtrace.join("\n") }
      raise Exceptions::CollectorException, message
    end
  end
    # curl -k -v -XGET -H "Authorization: Bearer $TOKEN" -H "Accept: application/json, */*" -H "User-Agent: kubectl/v1.9.2 (darwin/amd64) kubernetes/5fa2db2" 
    # https://cluster02.analytics.dev.6fusion.com/api/v1/namespaces/default/pods/aws-node-watchdog-cc68fdd75-56r9r/log
    # determine whether we want to use kubeclient
    # how to operate in the localhost 

end
