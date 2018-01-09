# This class is responsible for initializing the object that contains all the configuration
# information provided by the end user
class InventoryConfig
  attr_reader :kube, :kubelet, :on_premise

  def initialize
    @kube = {
      host:              "",
      url:               "",
      token:             "",
      headers:           {},
      verify_ssl:        true }

    @kubelet = {
      protocol:           "",
      port:               "",
      cgroup_namespace:   "/system.slice/docker-" }
    
    @on_premise = {
      url:               "",
      token:             "",
      verify_ssl:        true,
      organization_id:   "" }

    # Kubernetes API values
    kube_host = ENV['KUBERNETES_HOST'].empty? ? ENV['KUBERNETES_SERVICE_HOST'] : ENV['KUBERNETES_HOST']
    kube_port = ENV['KUBERNETES_PORT'].empty? ? ENV['KUBERNETES_SERVICE_PORT'] : ENV['KUBERNETES_PORT']
    kube_token = ENV['KUBERNETES_TOKEN'].empty? File.read('/var/run/secrets/kubernetes.io/serviceaccount/token') : ENV['KUBERNETES_TOKEN']
    @kube[:verify_ssl] = ENV['KUBERNETES_VERIFY_SSL']&.match(/^true|yes|1$/i)
    kube_use_ssl = ENV['KUBERNETES_USE_SSL']&.match(/^true|yes|1$/i) || kube_port.eql?('443')
    kube_protocol = kube_use_ssl ? 'https' : 'http'
    @kube[:host] = kube_host
    @kube[:url] = "#{kube_protocol}://#{kube_host}:#{kube_port}/api/#{KUBE_API_VERSION}"
    @kube[:token] = kube_token
    @kube[:headers] = {Authorization: "Bearer #{kube_token}"} if kube_use_ssl && !kube_token.to_s.empty?

    @kubelet[:protocol] = kube_use_ssl ? 'https' : 'http'
    @kubelet[:port] = ENV['KUBELET_PORT'] || 10250

    # Meter API values
    on_premise_host = ENV['METER_API_HOST']
    on_premise_port = ENV['METER_API_PORT']
    on_premise_protocol = ENV['METER_API_USE_SSL']&.match(/^true|yes|1$/i) ? 'https' : 'http'

    @on_premise[:url] = "#{on_premise_protocol}://#{on_premise_host}:#{on_premise_port}/api/#{ONPREMISE_API_VERSION}"
    @on_premise[:token] = ENV['METER_API_TOKEN'] || ""
    @on_premise[:verify_ssl] = ENV['METER_API_VERIFY_SSL']&.match(/^true|yes|1$/i) ? true : false
    @on_premise[:organization_id] = ENV['METER_ORGANIZATION_ID']

    $logger.debug "Configuration:\nkube: #{@kube}\nkubelet: #{@kubelet}\nmeter:#{@on_premise}"
  end

end
