class Pod
  include Mongoid::Document

  field :name,      type: String
  field :namespace, type: String
  field :uid,       type: String
  field :status,    type: String
  field :host_ip,   type: String
  field :ip,        type: String


  field :ready_containers, type: Set

  validates :name, :infrastructure, presence: true

  has_many   :machines
  belongs_to :infrastructure

  def initialize(params={})
    # The hash of params returned from the Kubernetes API contains a lot more fields than we need, so we filter down to just the required stuff
    if params.empty?
      super
    else
      ready_containers = params['status']['containerStatuses'].select{|stat| stat['ready']}.map{|stat| stat['name']}

      super(name: params['metadata']['name'],
            namespace: params['metadata']['namespace'],
            uid: params['metadata']['uid'],
            status: params['status']['phase'],
            ip: params['status']['podIP'],
            host_ip: params['status']['hostIP'],
            ready_containers: ready_containers)

    end
  end

end
