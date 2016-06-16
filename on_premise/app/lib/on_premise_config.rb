# This class is responsible for initializing the object that contains all the configuration
# information provided by the end user
class K8scollectorConfig
  attr_reader :kube, :on_premise

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
    kube_host = readfile("#{SECRETS_DIR}/kube/kube-host")
    raise "Kubernetes host is not present in the kube-secret" if kube_host.empty?
    kube_port = readfile("#{SECRETS_DIR}/kube/kube-port")
    raise "Kubernetes port is not present in the kube-secret" if kube_port.empty?
    kube_token = readfile("#{SECRETS_DIR}/kube/kube-token")
    kube_token = readfile(KUBE_TOKEN_LOCATION) if kube_token.empty? && File.exist?(KUBE_TOKEN_LOCATION)
    @kube[:verify_ssl] = readfile_int("#{SECRETS_DIR}/kube/kube-verify-ssl")
    kube_use_ssl =  readfile_int("#{SECRETS_DIR}/kube/kube-use-ssl")
    kube_protocol = kube_use_ssl ? 'https' : 'http'
    @kube[:host] = kube_host
    @kube[:url] = "#{kube_protocol}://#{kube_host}:#{kube_port}/api/#{KUBE_API_VERSION}"
    @kube[:token] = kube_token
    @kube[:headers] = {Authorization: "Bearer #{kube_token}"} if kube_use_ssl && !kube_token.to_s.empty?

    # Kubernetes cAdvisor values
    cadvisor_host = readfile("#{SECRETS_DIR}/kube/cadvisor-host")
    raise "cAdvisor host is not present in the kube-secret" if cadvisor_host.empty?
    @kube[:cadvisor_host] = cadvisor_host

    cadvisor_port = readfile("#{SECRETS_DIR}/kube/cadvisor-port")
    raise "cAdvisor port is not present in the kube-secret" if cadvisor_port.empty?
    @kube[:cadvisor_port] = cadvisor_port

    # On Premise API values
    on_premise_host = readfile("#{SECRETS_DIR}/on-premise/host")
    raise "On Premise API host is not present in the on-premise-secret" if on_premise_host.empty?
    on_premise_port = readfile("#{SECRETS_DIR}/on-premise/port")
    raise "On Premise API port is not present in the on-premise-secret" if on_premise_port.empty?
    on_premise_protocol = readfile_int("#{SECRETS_DIR}/on-premise/use-ssl") ? 'https' : 'http'
    @on_premise[:url] = "#{on_premise_protocol}://#{on_premise_host}:#{on_premise_port}/api/#{ONPREMISE_API_VERSION}"
    @on_premise[:token] = readfile("#{SECRETS_DIR}/on-premise/token")
    @on_premise[:verify_ssl] = readfile_int("#{SECRETS_DIR}/on-premise/verify-ssl")
    @on_premise[:organization_id] = readfile("#{SECRETS_DIR}/on-premise/organization-id")
  end

  private

  def readfile(filepath)
    File.exist?(filepath) ? File.read(filepath).chomp.strip : ''
  end

  def readfile_int(filepath)
    !!(File.exist?(filepath) ? (File.read(filepath).chomp.strip).to_i.nonzero? : nil)
  end

end