module S3
  class Object < Driver::Model
    def initialize(api, bucket_name, object_name, opts = {})
      super(api)
      @bucket = bucket_name
      @name = object_name
      @opts = opts
    end

    def name
      @name
    end

    def size
      @opts["Size"][0].to_i
    end

    def etag
      @opts["ETag"][0]
    end

    def lastmodified
      Time.parse(@opts["LastModified"][0])
    end

    def read(range = nil)
      @api.get_object(@bucket, @name, range)
    end

    def write(data, options = {})
      if data.is_a?(String)
        data = StringIO.new(data)
      elsif data.is_a?(Pathname)
        data = File.open(data, 'rb')
      elsif data.respond_to?(:read) && data.respond_to?(:eof?)
      end

      unless options[:multipart]
        @api.create_object(@bucket, @name, options) do
          data
        end
      else
        @api.create_multipart_object(@bucket, @name, options) do
          data
        end
      end
      data.close

      nil
    end

    def delete
      @api.delete_object(@bucket, @name)
    end
  end
end
