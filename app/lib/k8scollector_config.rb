class K8scollectorConfig
  attr_accessor :kube, :on_premise

  def initialize
    @kube = {
      url:          "",
      token:        "",
      verify_ssl:   true,
      cadvisor_url: ""
    }
    @on_premise = {
      url:               "",
      token:             "",
      verify_ssl:        true,
      organization_id:   0,
      infrastructure_id: 0
    }
    # Kubernetes API values
    kube_host = File.exist?("#{SECRETS_DIR}/kube/kube-host") ? File.read("#{SECRETS_DIR}/kube/kube-host").chomp.strip : ""
    raise "Kubernetes host is not present in the kube-secret" if kube_host.empty?
    kube_port = File.exist?("#{SECRETS_DIR}/kube/kube-port") ? File.read("#{SECRETS_DIR}/kube/kube-port").chomp.strip : ""
    raise "Kubernetes port is not present in the kube-secret" if kube_port.empty?
    kube_token = File.exist?("#{SECRETS_DIR}/kube/kube-token") ? File.read("#{SECRETS_DIR}/kube/kube-token").chomp.strip : ""
    kube_token = File.read('/var/run/secrets/kubernetes.io/serviceaccount/token').chomp.strip if kube_token.empty? && File.exist?('/var/run/secrets/kubernetes.io/serviceaccount/token')
    kube_protocol = kube_token.empty? ? 'http' : 'https'
    @kube[:url] = "#{kube_protocol}://#{kube_host}:#{kube_port}/api/#{KUBE_API_VERSION}"
    @kube[:token] = kube_token
    @kube[:verify_ssl] = !!(File.exist?("#{SECRETS_DIR}/kube/kube-verify-ssl") ? (File.read("#{SECRETS_DIR}/kube/kube-verify-ssl").chomp.strip).to_i.nonzero? : nil)

    # Kubernetes cAdvisor values
    cadvisor_host = File.exist?("#{SECRETS_DIR}/kube/cadvisor-host") ? File.read("#{SECRETS_DIR}/kube/cadvisor-host").chomp.strip : ""
    raise "cAdvisor host is not present in the kube-secret" if cadvisor_host.empty?
    cadvisor_port = File.exist?("#{SECRETS_DIR}/kube/cadvisor-port") ? File.read("#{SECRETS_DIR}/kube/cadvisor-port").chomp.strip : ""
    raise "cAdvisor port is not present in the kube-secret" if cadvisor_port.empty?
    cadvisor_protocol = 'http'  # As of today, cAdvisor only serves on http
    @kube[:cadvisor_url] = "#{cadvisor_protocol}://#{cadvisor_host}:#{cadvisor_port}/api/#{CADVISOR_API_VERSION}"

    # On Premise API values
    on_premise_host = File.exist?("#{SECRETS_DIR}/on-premise/host") ? File.read("#{SECRETS_DIR}/on-premise/host").chomp.strip : ""
    raise "On Premise API host is not present in the on-premise-secret" if on_premise_host.empty?
    on_premise_port = File.exist?("#{SECRETS_DIR}/on-premise/port") ? File.read("#{SECRETS_DIR}/on-premise/port").chomp.strip : ""
    raise "On Premise API port is not present in the on-premise-secret" if on_premise_port.empty?
    on_premise_protocol = (!!(File.exist?("#{SECRETS_DIR}/on-premise/use-ssl") ? (File.read("#{SECRETS_DIR}/on-premise/use-ssl").chomp.strip).to_i.nonzero? : nil)) ? 'https' : 'http'
    @on_premise[:url] = "#{on_premise_protocol}://#{on_premise_host}:#{on_premise_port}"
    @on_premise[:token] = File.exist?("#{SECRETS_DIR}/on-premise/token") ? File.read("#{SECRETS_DIR}/on-premise/token").chomp.strip : ""
    @on_premise[:verify_ssl] = !!(File.exist?("#{SECRETS_DIR}/on-premise/verify-ssl") ? (File.read("#{SECRETS_DIR}/on-premise/verify-ssl").chomp.strip).to_i.nonzero? : nil)
    @on_premise[:organization_id] = File.read("#{SECRETS_DIR}/on-premise/organization-id").chomp.to_i if File.exist?("#{SECRETS_DIR}/on-premise/organization-id")
    @on_premise[:infrastructure_id] = File.read("#{SECRETS_DIR}/on-premise/infrastructure-id").chomp.to_i if File.exist?("#{SECRETS_DIR}/on-premise/infrastructure-id")
  end

end