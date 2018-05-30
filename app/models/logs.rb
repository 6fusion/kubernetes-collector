# {"timestamp":"2016-11-03T15:48:12.007Z","level":"INFO",
# "thread":"cromwell-system-akka.actor.default-dispatcher-4",
# logger":"akka.event.slf4j.Slf4jLogger",
# "message":"Slf4jLogger started","context":"default"}
class Log 
    include Mongoid::Document
    include Mongoid::Timestamps

    field :time,    type: DateTime     
    field :level,        type: String
   field :pod_name,       type: String
    # field :logger,       type: String
    field :message,      type: String
    # field :context,      type: String

    def initialize(params={})
        # The hash of params returned from the Kubernetes API contains a lot more fields than we need, so we filter down to just the required stuff
        if params.empty?
          super
        else    
        super(  pod_name: params[:pod_name],
                time: params[:time],
                level: params[:level],
                 message: params[:message]
        #         logger: params['logger'],
            
               # context: params['context'])
        )
        end
    end
    
end
    