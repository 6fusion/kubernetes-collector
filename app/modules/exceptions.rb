# This class is responsible for handle exceptions for collector
module Exceptions
  class CollectorException < StandardError
    def initialize(message)
      @message = message
    end
  end
end
