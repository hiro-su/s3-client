module S3
  class BucketCollection < Driver::Model
    include Enumerable

    def create(bucket_name)
      @api.create_bucket(bucket_name)
      bucket_named(bucket_name)
    end

    # @example
    #
    #   bucket = client.buckets[:mybucket],
    #   bucket = client.buckets['mybucket'],
    #
    # @param [String] bucket_name
    # @return [Bucket]
    def [] bucket_name
      bucket_named(bucket_name)
    end

    def each
      xml_doc = @api.buckets
      buckets = S3::Concerns::BucketsResult.new(xml_doc).buckets
      buckets.each do |bucket|
        yield bucket_named(bucket)
      end
    end

    private

    def bucket_named(bucket)
      S3::Bucket.new(@api, bucket.to_s)
    end
  end
end
