class Service
  include Mongoid::Document

  field :name,       type: String
  field :namespace,  type: String
  field :pod_ips,    type: Set


  def initialize(params={})
    # The hash of params returned from the Kubernetes API contains a lot more fields than we need, so we filter down to just the required stuff
    if params.empty?
      super
    else
      subsets = params['subsets'].select{|subset| subset.key?('addresses')}
      ips = subsets.map{|subset| subset['addresses'].map{|addy| addy['ip'] }}.flatten
      super(name: params['metadata']['name'],
            namespace: params['metadata']['namespace'],
            pod_ips: ips)
    end
  end

end
