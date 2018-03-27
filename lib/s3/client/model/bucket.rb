module S3
  class Bucket < Driver::Model
    def initialize(api, bucket_name)
      super(api)
      @name = bucket_name
    end

    def name
      @name
    end

    def delete
      @api.delete_bucket(@name)
    end

    def objects(prefix: nil)
      S3::ObjectCollection.new(@api, @name)
    end
  end
end
