# This class is responsible for initializing the object that contains all the configuration
# information provided by the end user
class CleanCacheConfig
  attr_reader :kube, :on_premise

  def initialize
    @on_premise = {
      data_age_period: ""
    }
    # On Premise API values
    @on_premise[:data_age_period] = readfile_int("#{SECRETS_DIR}/on-premise/data-age-period").minutes 
  end

  private

  def readfile_int(filepath)
    File.exist?(filepath) ? File.read(filepath).to_i : DATA_AGE_PERIOD_DEFAULT
  end
end