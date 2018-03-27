module S3
  class Client
    model Bucket, BucketCollection, :Object, ObjectCollection

    module Storage
      def buckets
        S3::BucketCollection.new(@api)
      end

      def objects(bucket)
        S3::ObjectCollection.new(@api, bucket)
      end

      def create_bucket(bucket)
        @api.create_bucket(bucket)

        S3::Bucket.new(@api, bucket)
      end

      def delete_bucket(bucket)
        @api.delete_bucket(bucket)

        nil
      end

      def delete_object(bucket, object)
        @api.delete_object(bucket, object)

        nil
      end

      #
      # == options ==
      # * <tt>label</tt> - label
      # * <tt>jobs</tt> - count of executing pararell
      def import(db_name, table, file_path, options = {})
        @api.import(db_name, table, file_path, options)

        nil
      end
    end
  end
end
