module S3
  class Client::API
    class RestParameter

      def initialize(method, resource, cano_resource: nil, query_params: {},
                     parameters: {}, bucket: '', content_type: nil, import: false,
                     raw_data: false, blank_body: false, headers: {}, multipart: false)

        @method = method
        @resource = resource
        @cano_resource = cano_resource
        @query_params = query_params
        @parameters = parameters
        @bucket = bucket
        @content_type = content_type
        @import = import
        @raw_data = raw_data
        @blank_body = blank_body
        @headers = headers
        @multipart = multipart
      end

      attr_reader :method
      attr_reader :resource
      attr_reader :cano_resource
      attr_reader :query_params
      attr_reader :parameters
      attr_reader :bucket
      attr_reader :content_type
      attr_reader :headers

      def url(uri, force_path_style = false)
        url = uri.host
        url += ":#{uri.port}" unless uri.port == 80 || uri.port == 443

        if @bucket.present?
          if force_path_style
            url += '/' unless url.end_with? "/"
            url += @bucket
          else
            url = [@bucket, url].join('.')
            url += '/' unless url.end_with? "/"
          end
        end

        if @bucket.blank? || @resource != '/'
          url = File.join(url, @resource)
        end

        url += '/' if url.split('/').last == @bucket
        url += '?' if @cano_resource.present? || @query_params.present?
        url += @cano_resource if @cano_resource
        url += '&' if @cano_resource.present? && @query_params.present?
        url += "#{@query_params.to_param}" if @query_params.present?

        uri.scheme + '://' + url
      end

      def http_verb
        @method.to_s.upcase
      end

      def signature_content_type
        result = ""
        if @content_type.present?
          result << @content_type
        end

        result << "\n"

        result
      end

      def authentication(access_key_id, secret_access_key, force_path_style)

        "AWS" + " " + access_key_id + ":" + signature(secret_access_key, force_path_style)
      end

      def signature(secret_access_key, force_path_style = false)
        http_verb = "#{self.http_verb}\n"
        content_md5 = "\n"
        content_type = signature_content_type
        date = "#{calc_date}\n"

        canonicalized_aws_headers = ""

        string_to_sign = http_verb + content_md5 + content_type + date +
            canonicalized_aws_headers + canonicalized_resource(force_path_style)

        digest = OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha1'), secret_access_key, string_to_sign)
        Base64.encode64(digest).strip
      end

      def canonicalized_resource(force_path_style = false)
        result = ''

        if @bucket.present?
          result = '/'
          result += "#{@bucket}/"
        end

        if @bucket.blank? || @resource != '/'
          result = File.join(result, @resource)
        end

        result += '?' if @cano_resource.present?
        result += @cano_resource if @cano_resource

        result
      end

      def calc_date
        return @date if @date
        @date = Time.now.httpdate

        @date
      end

      def import?
        @import
      end

      def multipart?
        @multipart
      end

      def raw_data?
        @raw_data
      end

      def blank_body?
        @blank_body
      end

      def to_s
        [
          "method:#{@method}",
          "resource: #{@resource}",
          "cano_resource: #{@cano_resource}",
          "query_params: #{@query_params}",
          "bucket: #{@bucket}",
          "parameters: #{@parameters}",
          "headers: #{@headers}"
        ].join(", ")
      end

    end
  end
end
