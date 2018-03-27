module S3
  class Client
    class APIFailure < StandardError
      attr_accessor :api_code
      attr_accessor :api_message
      attr_accessor :api_status
      attr_accessor :api_request_id
      attr_accessor :api_resource
    end

    class ParameterInvalid < StandardError
    end

    class APIOptionInvalid < StandardError
    end

    class StatusInvalid < StandardError
    end
  end
end