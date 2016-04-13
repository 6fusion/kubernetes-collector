module K8scollector

  def init_logger
    $logger = Logger.new(STDOUT)
    $logger.level = Logger::DEBUG
  end

  def init_mongodb
    Mongoid.load! 'config/mongoid.yml'
  end

  def load_configuration
    $config = { kube: {
                        kube_host:         "",
                        kube_port:         "",
                        kube_token:        "",
                        cadvisor_host:     "",
                        cadvisor_port:     ""
                      },
                on_premise: {
                        host:              "",
                        port:              "",
                        token:             "",
                        organization_id:   0,
                        infrastructure_id: 0
                      }
              }
    $config[:kube][:kube_host]     = File.read("#{SECRETS_DIR}/kube/kube-host").chomp if File.exist?("#{SECRETS_DIR}/kube/kube-host")
    $config[:kube][:kube_port]     = File.read("#{SECRETS_DIR}/kube/kube-port").chomp if File.exist?("#{SECRETS_DIR}/kube/kube-port")
    $config[:kube][:kube_token]    = File.read("#{SECRETS_DIR}/kube/kube-token").chomp if File.exist?("#{SECRETS_DIR}/kube/kube-token")
    $config[:kube][:cadvisor_host] = File.read("#{SECRETS_DIR}/kube/cadvisor-host").chomp if File.exist?("#{SECRETS_DIR}/kube/cadvisor-host")
    $config[:kube][:cadvisor_port] = File.read("#{SECRETS_DIR}/kube/cadvisor-port").chomp if File.exist?("#{SECRETS_DIR}/kube/cadvisor-port")
    $config[:on_premise][:host]    = File.read("#{SECRETS_DIR}/on-premise/host").chomp if File.exist?("#{SECRETS_DIR}/on-premise/host")
    $config[:on_premise][:port]    = File.read("#{SECRETS_DIR}/on-premise/port").chomp if File.exist?("#{SECRETS_DIR}/on-premise/port")
    $config[:on_premise][:token]   = File.read("#{SECRETS_DIR}/on-premise/token").chomp if File.exist?("#{SECRETS_DIR}/on-premise/token")
    $config[:on_premise][:organization_id]   = File.read("#{SECRETS_DIR}/on-premise/organization-id").chomp.to_i if File.exist?("#{SECRETS_DIR}/on-premise/organization-id")
    $config[:on_premise][:infrastructure_id] = File.read("#{SECRETS_DIR}/on-premise/infrastructure-id").chomp.to_i if File.exist?("#{SECRETS_DIR}/on-premise/infrastructure-id")
  end

end