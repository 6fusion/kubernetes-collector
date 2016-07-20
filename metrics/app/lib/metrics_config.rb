# This class is responsible for initializing the object that contains all the configuration
# information provided by the end user
class MetricsConfig
  attr_reader :kube, :container

  def initialize
    @kube = {
      cadvisor_host:     '',
      cadvisor_port:     '',
      cadvisor_protocol: 'http'  # As of today, cAdvisor only serves on http
    }
    @container = {
      hostname: ''
    }

    # Set the hostname of the current running container
    stdout, stderr, status = Open3.capture3('hostname -f')
    stdout = stdout.chomp.strip
    if !stdout.empty? && stderr.empty?
      @container[:hostname] = stdout
    else
      raise 'Could not get the hostname of the current running container'
    end

    # Kubernetes cAdvisor values
    cadvisor_host = readfile("#{SECRETS_DIR}/kube/cadvisor-host")
    raise "cAdvisor host is not present in the kube-secret" if cadvisor_host.empty?
    @kube[:cadvisor_host] = cadvisor_host

    cadvisor_port = readfile("#{SECRETS_DIR}/kube/cadvisor-port")
    raise "cAdvisor port is not present in the kube-secret" if cadvisor_port.empty?
    @kube[:cadvisor_port] = cadvisor_port
  end

  private

  def readfile(filepath)
    File.exist?(filepath) ? File.read(filepath).chomp.strip : ''
  end
end