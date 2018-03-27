module S3
  class ObjectCollection < Driver::Model
    include Enumerable

    def initialize(api, bucket_name)
      super(api)
      @bucket = bucket_name
    end

    def [](object_name)
      object_named(object_name)
    end

    def where(prefix: nil, delimiter: nil)
      @prefix = prefix
      @delimiter = delimiter

      self
    end

    def each
      options = {}
      if @prefix
        options = options.merge(prefix: @prefix)
      end

      if @delimiter
        options = options.merge(delimiter: @delimiter)
      end

      marker = nil
      truncated = false
      begin
        if marker.present?
          options = options.merge(marker: marker)
        end
        xml_doc = @api.objects(@bucket, options)
        objects_result = S3::Concerns::ObjectsResult.new(xml_doc)
        objects = objects_result.full_objects

        truncated = objects_result.truncated?
        next_marker = objects_result.next_marker
        if next_marker.nil?
          marker = objects.last['Key'][0] if objects.present?
        else
          marker = next_marker
        end

        objects.each do |object|
          yield object_opts(object)
        end
      end while truncated
    end

    private

    def object_named(object_name)
      S3::Object.new(@api, @bucket, object_name.to_s)
    end

    def object_opts(object_opts)
      S3::Object.new(@api, @bucket, object_opts["Key"][0], object_opts)
    end
  end
end
