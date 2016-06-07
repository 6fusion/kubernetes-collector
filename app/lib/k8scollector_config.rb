class K8scollectorConfig
  attr_accessor :kube, :on_premise

  def initialize
    @kube = {
      host:              "",
      url:               "",
      token:             "",
      headers:           {},
      verify_ssl:        true,
      cadvisor_host:     "",
      cadvisor_port:     "",
      cadvisor_protocol: "http"  # As of today, cAdvisor only serves on http
    }
    @on_premise = {
      url:               "",
      token:             "",
      verify_ssl:        true,
      organization_id:   ""
    }
    # Kubernetes API values
    kube_host = File.exist?("#{SECRETS_DIR}/kube/kube-host") ? File.read("#{SECRETS_DIR}/kube/kube-host").chomp.strip : ""
    raise "Kubernetes host is not present in the kube-secret" if kube_host.empty?
    kube_port = File.exist?("#{SECRETS_DIR}/kube/kube-port") ? File.read("#{SECRETS_DIR}/kube/kube-port").chomp.strip : ""
    raise "Kubernetes port is not present in the kube-secret" if kube_port.empty?
    kube_token = File.exist?("#{SECRETS_DIR}/kube/kube-token") ? File.read("#{SECRETS_DIR}/kube/kube-token").chomp.strip : ""
    kube_token = File.read('/var/run/secrets/kubernetes.io/serviceaccount/token').chomp.strip if kube_token.empty? && File.exist?('/var/run/secrets/kubernetes.io/serviceaccount/token')
    @kube[:verify_ssl] = !!(File.exist?("#{SECRETS_DIR}/kube/kube-verify-ssl") ? (File.read("#{SECRETS_DIR}/kube/kube-verify-ssl").chomp.strip).to_i.nonzero? : nil)
    kube_use_ssl = !!(File.exist?("#{SECRETS_DIR}/kube/kube-use-ssl") ? (File.read("#{SECRETS_DIR}/kube/kube-use-ssl").chomp.strip).to_i.nonzero? : nil)
    kube_protocol = kube_use_ssl ? 'https' : 'http'
    @kube[:host] = kube_host
    @kube[:url] = "#{kube_protocol}://#{kube_host}:#{kube_port}/api/#{KUBE_API_VERSION}"
    @kube[:token] = kube_token
    @kube[:headers] = {Authorization: "Bearer #{kube_token}"} if kube_use_ssl && !kube_token.to_s.empty?
    @kube[:verify_ssl] = !!(File.exist?("#{SECRETS_DIR}/kube/kube-verify-ssl") ? (File.read("#{SECRETS_DIR}/kube/kube-verify-ssl").chomp.strip).to_i.nonzero? : nil)

    # Kubernetes cAdvisor values
    cadvisor_host = File.exist?("#{SECRETS_DIR}/kube/cadvisor-host") ? File.read("#{SECRETS_DIR}/kube/cadvisor-host").chomp.strip : ""
    raise "cAdvisor host is not present in the kube-secret" if cadvisor_host.empty?
    @kube[:cadvisor_host] = cadvisor_host
    
    cadvisor_port = File.exist?("#{SECRETS_DIR}/kube/cadvisor-port") ? File.read("#{SECRETS_DIR}/kube/cadvisor-port").chomp.strip : ""
    raise "cAdvisor port is not present in the kube-secret" if cadvisor_port.empty?
    @kube[:cadvisor_port] = cadvisor_port

    # On Premise API values
    on_premise_host = File.exist?("#{SECRETS_DIR}/on-premise/host") ? File.read("#{SECRETS_DIR}/on-premise/host").chomp.strip : ""
    raise "On Premise API host is not present in the on-premise-secret" if on_premise_host.empty?
    on_premise_port = File.exist?("#{SECRETS_DIR}/on-premise/port") ? File.read("#{SECRETS_DIR}/on-premise/port").chomp.strip : ""
    raise "On Premise API port is not present in the on-premise-secret" if on_premise_port.empty?
    on_premise_protocol = (!!(File.exist?("#{SECRETS_DIR}/on-premise/use-ssl") ? (File.read("#{SECRETS_DIR}/on-premise/use-ssl").chomp.strip).to_i.nonzero? : nil)) ? 'https' : 'http'
    @on_premise[:url] = "#{on_premise_protocol}://#{on_premise_host}:#{on_premise_port}/api/#{ONPREMISE_API_VERSION}"
    @on_premise[:token] = File.exist?("#{SECRETS_DIR}/on-premise/token") ? File.read("#{SECRETS_DIR}/on-premise/token").chomp.strip : ""
    @on_premise[:verify_ssl] = !!(File.exist?("#{SECRETS_DIR}/on-premise/verify-ssl") ? (File.read("#{SECRETS_DIR}/on-premise/verify-ssl").chomp.strip).to_i.nonzero? : nil)
    @on_premise[:organization_id] = File.read("#{SECRETS_DIR}/on-premise/organization-id").chomp if File.exist?("#{SECRETS_DIR}/on-premise/organization-id")
  end

end