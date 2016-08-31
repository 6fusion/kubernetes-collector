# This class is responsible for initializing the object that contains all the configuration
# information provided by the end user
class OnPremiseConfig
  attr_reader :on_premise

  def initialize
    @on_premise = {
      url:               "",
      token:             "",
      verify_ssl:        true,
      organization_id:   ""
    }

    # On Premise API values
    on_premise_host = readfile("#{SECRETS_DIR}/on-premise/host")
    raise "On Premise API host is not present in the on-premise-secret" if on_premise_host.empty?
    on_premise_port = readfile("#{SECRETS_DIR}/on-premise/port")
    raise "On Premise API port is not present in the on-premise-secret" if on_premise_port.empty?
    on_premise_protocol = readfile_boolean("#{SECRETS_DIR}/on-premise/use-ssl") ? 'https' : 'http'
    @on_premise[:url] = "#{on_premise_protocol}://#{on_premise_host}:#{on_premise_port}/api/#{ONPREMISE_API_VERSION}"
    @on_premise[:token] = readfile("#{SECRETS_DIR}/on-premise/token")
    @on_premise[:verify_ssl] = readfile_boolean("#{SECRETS_DIR}/on-premise/verify-ssl")
    @on_premise[:organization_id] = readfile("#{SECRETS_DIR}/on-premise/organization-id")
  end

  private

  def readfile(filepath)
    File.exist?(filepath) ? File.read(filepath).chomp.strip : ''
  end

  def readfile_boolean(filepath)
    config_value = File.exist?(filepath) ? File.read(filepath).chomp.strip : ''
    ['true','1'].any? { |word| config_value.include?(word) }
  end
end
