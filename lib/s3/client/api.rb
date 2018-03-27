module S3
  class Client
    class API < Driver::API
      drive Storage

      autoload :RestParameter, 's3/client/api/rest_parameter'

      def initialize(access_key_id, secret_access_key,
                     endpoint: S3::Settings.endpoint,
                     force_path_style: S3::Settings.force_path_style,
                     location: S3::Settings.location,
                     debug: S3::Settings.debug)

        require 'time'
        require 'base64'
        require 'rexml/document'
        require 'net/http'
        require 'xmlsimple'
        require 'ipaddr'
        require 'httpclient'
        require 'stringio'

        @access_key_id = access_key_id
        @secret_access_key = secret_access_key

        unless [TrueClass, FalseClass].any? { |c| force_path_style.kind_of?(c) }
           raise S3::Client::APIOptionInvalid.new("force_path_style is not boolean:#{force_path_style}")
        end

        unless [TrueClass, FalseClass].any? { |c| debug.kind_of?(c) }
          raise S3::Client::APIOptionInvalid.new("debug is not boolean:#{debug}")
        end

        @endpoint = endpoint
        @force_path_style = force_path_style
        @location = location
        @debug = debug

        @http_client = HTTPClient.new
        @http_client.connect_timeout = 300
        @http_client.send_timeout    = 300
        @http_client.receive_timeout = 300
        @http_client.debug_dev = STDERR if @debug
      end

      attr_accessor :access_key_id, :secret_access_key, :endpoint

      def force_path_style?
        @force_path_style
      end

      def execute_storage(rest_parameter, &block)
        unless @access_key_id
           raise S3::Client::ParameterInvalid.new("missing access_key_id")
        end

        unless @secret_access_key
           raise S3::Client::ParameterInvalid.new("missing secret_access_key")
        end

        response = handle_api_failure(rest_parameter) do
          rest_client(:storage, rest_parameter, &block)
        end

        if response.present?
          data = if rest_parameter.raw_data?
                   response.body
                 else
                   REXML::Document.new(response.body)
                 end || ''

          if data.present?
            STDERR.print "\n\n" if @debug
          end

          data.instance_eval {
            class << self
              attr_accessor :headers
            end
          }
          data.headers = response.header
          return data.freeze
        end
      end

      def download_signature(expire_at, bucket, output_object)
        http_verb = "GET\n"
        content_md5 = "\n"
        content_type = "\n"
        expire = "#{expire_at}\n"

        string_to_sign = http_verb + content_md5 + content_type + expire +
            canonicalized_resource(bucket, output_object)

        digest = OpenSSL::HMAC::digest(OpenSSL::Digest::SHA1.new, @secret_access_key, string_to_sign)
        Base64.encode64(digest).strip
      end

      private

      def canonicalized_resource(bucket, object)
        result = ''

        unless @force_path_style
          result = '/'
          result += "#{bucket}"
        end

        File.join(result, object)
      end

      # API Error Handling
      # @param [S3::Client::API::RestParameter] rest_parameter APIへの入力値
      # @param [Proc] block リクエスト処理が入るブロック
      def handle_api_failure(rest_parameter, &block)
        response = nil

        begin
          response = block.call

          #unless response.try(:status).to_s =~ /^(2\d\d|3\d\d)$/
          unless response.try(:status).to_s =~ /^(2\d\d)$/
            raise S3::Client::APIFailure
          end

          return response
        rescue S3::Client::APIFailure
          msg = "api_failure #{rest_parameter}"
          api_failure = S3::Client::APIFailure.new(msg)
          raise api_failure if response.blank?

          xml_doc = REXML::Document.new(response.body)

          if xml_doc && xml_doc.elements['Error/Code']
            if xml_doc.elements['Error/Code']
              api_failure.api_code = xml_doc.elements['Error/Code'].text
            end
            if xml_doc.elements['Error/Message']
              api_failure.api_message = xml_doc.elements['Error/Message'].text
            end
            if xml_doc.elements['Error/Status']
              api_failure.api_status = xml_doc.elements['Error/Status'].text.to_i
            end
            if xml_doc.elements['Error/RequestId']
              api_failure.api_request_id = xml_doc.elements['Error/RequestId'].text
            end
            if xml_doc.elements['Error/Resource']
              api_failure.api_resource = xml_doc.elements['Error/Resource'].text
            end
          else
            api_failure.api_code = nil
            api_failure.api_message = response.body
            api_failure.api_status = response.try(:status)
            api_failure.api_request_id = nil
            api_failure.api_resource = response.http_header.request_uri
          end

          raise api_failure
        end

        response
      end

      def rest_client(kind, rest_parameter, &block)
        url = rest_parameter.url(host_uri(kind), @force_path_style)

        rest_parameter.headers.merge!({
          Authorization: rest_parameter.authentication(@access_key_id, @secret_access_key, @force_path_style),
          Date: rest_parameter.calc_date,
          Host: host_name(kind, rest_parameter.bucket),
          Accept: '*/*; q=0.5, application/xml',
          'Accept-Encoding' => 'gzip, deflate',
          'User-Agent' => "s3-client (#{S3::VERSION})"
        })

        parameters = rest_parameter.parameters

        unless rest_parameter.headers['Content-Type']
          if rest_parameter.content_type
            rest_parameter.headers.merge!(
                'Content-Type' => rest_parameter.content_type
            )
          end
        end

        payload = if parameters.present? || rest_parameter.blank_body?
                    parameters
                  elsif block_given?
                    block.call
                  end

        unless rest_parameter.headers['Content-Length']
          rest_parameter.headers.merge!(
              'Content-Length' => payload ? payload.size.to_s : 0.to_s
          )
        end

        STDERR.print "\n" if @debug

        headers = rest_parameter.headers
        case rest_parameter.method
          when :get
            @http_client.get(url, nil, headers)

          when :post
            @http_client.post(url, payload, headers)

          when :put
            @http_client.put(url, payload, headers)

          when :delete
            @http_client.delete(url, nil, headers)

        end
      end

      def host_name(kind, bucket)
        uri = host_uri(kind)
        result = uri.host

        if kind == :storage
          return result if valid_ip?(result)

          if !@force_path_style && bucket.present?
            result = "#{bucket}.#{result}"
          end
        end

        unless uri.port == 80 || uri.port == 443
          result += ":#{uri.port}"
        end

        result
      end

      def valid_ip?(str)
        begin
          IPAddr.new(str)
          true
        rescue
          false
        end
      end

      def host_uri(kind)
        host_url = case kind
                     when :storage
                       @endpoint
                   end

        raise 'illegal kind' if host_url.blank?

        URI.parse(host_url)
      end

    end
  end
end
