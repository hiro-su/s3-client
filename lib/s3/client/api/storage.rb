require 'zlib'
require 'mime-types'
require 'singleton'

module S3
  class Client::API
    module Storage
      def buckets
        execute_storage(RestParameter.new(:get, '/'))
      end

      def objects(bucket, prefix: nil, max: nil, marker: nil, delimiter: nil)
        resource = '/'
        query_params = {}
        if prefix
          query_params.merge!('prefix' => prefix)
        end

        if max
          query_params.merge!('max-keys' => max)
        end

        if marker
          query_params.merge!('marker' => marker)
        end

        if delimiter
          query_params.merge!('delimiter' => delimiter)
        end

        execute_storage(RestParameter.new(:get, resource, bucket: bucket, query_params: query_params))
      end

      def create_bucket(bucket, options = {})
        resource = '/'

        options = options.merge(bucket: bucket, content_type: 'application/xml')
        execute_storage(RestParameter.new(:put, resource, options)) do
          root = REXML::Element.new('CreateBucketConfiguration')
          root.add_attribute('xmlns', 'http://s3.amazonaws.com/doc/2006-03-01/')
          child = REXML::Element.new('LocationConstraint')
          child.add_text(@location)
          root.add_element(child)
          root
        end
      end

      def create_object(bucket, object_name, options = {}, &block)
        resource = "/#{object_name}"

        type = MIME::Types.type_for(object_name).first
        content_type = type ? type.to_s : 'application/octet-stream'
        options = options.merge(bucket: bucket, content_type: content_type)
        execute_storage(RestParameter.new(:put, resource, options), &block)
      end

      def create_multipart_object(bucket, object_name, options = {}, &block)
        mu = MultipartUpload.new(bucket, object_name, options) do
          self
        end

        # Initiate Multipart Upload
        upload_id = mu.initiate_multipart_upload

        begin
          # Upload Part
          upload_objects = mu.upload_part(upload_id, &block)

          # Complete Multipart Upload
          mu.complete_multipart_upload(upload_id, upload_objects)

        rescue => e
          # Abort Multipart Upload
          mu.abort_multipart_upload(upload_id)

          raise e
        end
      end

      def get_object(bucket, object, range = nil)
        resource = "/#{object}"
        headers = {}
        if range
          bt = "bytes=#{range.first}-"
          bt += "#{range.last}" if range.last != -1
          headers[:Range] = bt
        end
        execute_storage(RestParameter.new(:get, resource, bucket: bucket, raw_data: true, headers: headers))
      end

      def delete_bucket(bucket)
        resource = '/'
        execute_storage(RestParameter.new(:delete, resource, bucket: bucket))
      end

      def delete_object(bucket, object)
        resource = "/#{object}"
        execute_storage(RestParameter.new(:delete, resource, bucket: bucket, content_type: 'application/json'))
      end

      def import(db_name, tbl_name, file_paths, options = {})
        _import = Import.new(db_name, tbl_name, file_paths, options) do
          self
        end

        # calc label suffix => Fixnum
        suffix = _import.calc_label_suffix

        # import execute
        upload_objects = _import.execute(suffix)

        STDERR.puts "finished upload #{upload_objects.size} objects."
        STDERR.puts
        STDERR.puts 'upload_objects:'
        upload_objects.each do |o|
          STDERR.puts o
        end
      end

      private

      class Import
        def initialize(db_name, tbl_name, file_paths, options = {}, &block)
          @db_name = db_name
          @tbl_naem = tbl_name
          @file_paths = file_paths
          @jobs = options.delete(:jobs) || 1
          @label = options.delete(:label) || 'label'
          @splitsz = options.delete(:splitsz) || 100 * 1024 ** 2 #100M
          @api = block[]

          import_parameter = ImportParameter.instance
          import_parameter.db_name = db_name
          import_parameter.tbl_name = tbl_name
          import_parameter.label = @label

          if %w(_ .).include? @label[0]
            raise S3::Client::ParameterInvalid.new("label should not start with '_' or '.'")
          end

          STDERR.puts "Initialize...\njobs: #{@jobs}, splitsz: #{@splitsz}"
        end

        def calc_label_suffix
          prefix = ImportParameter.instance.storage_prefix
          xml_doc = @api.objects(@db_name, prefix: prefix)
          objects_result = S3::Concerns::ObjectsResult.new(xml_doc)
          objects = objects_result.objects

          return 0 if objects.blank?

          objects.map { |o| o.scan(/#{@label}_(\d+)/) }.flatten.map(&:to_i).sort.reverse.first.try(:+, 1)
        end

        def execute(suffix)
          file_paths = @file_paths.is_a?(String) ? [@file_paths] : @file_paths

          upload_objects = []
          file_paths.each do |file_path|
            file_index = if file_path.end_with?('.gz')
                            import_gz_file(file_path, suffix, upload_objects)
                          elsif file_path == "-"
                            import_stream($stdin, suffix, upload_objects)
                          else
                            import_text_file(file_path, suffix, upload_objects)
                          end

            suffix += file_index
          end

          return upload_objects
        end

        def import_gz_file(file_path, suffix, upload_objects)
          import_stream(Zlib::GzipReader.open(file_path), suffix, upload_objects)
        rescue Zlib::Error
          #if not gzip
          import_text_file(file_path, suffix, upload_objects)
        end

        def import_text_file(file_path, suffix, upload_objects)
          import_stream(File.open(file_path), suffix, upload_objects)
        end

        def import_stream(ifp, suffix, upload_objects)
          q = SizedQueue.new(@jobs)
          th = Array.new(@jobs) {
            Thread.new{
              while data = q.pop
                break unless data
                STDERR.puts "> starting upload part #{data[2]}, #{data[1].length}"
                execute_storage_detail(data[1], suffix + data[0])
                STDERR.puts "< finished upload part #{data[2]}, #{data[1].length}"
                upload_objects << ImportParameter.instance.object_label(suffix + data[0])
              end
              q.push nil
            }
          }

          begin
            file_index = 0
            import_index = ImportParameter.instance.index
            while true
              buffer = ifp.read(@splitsz)
              break unless buffer
              buffer.force_encoding("ASCII-8BIT")
              nline = ifp.gets
              if nline
                nline.force_encoding("ASCII-8BIT")
                buffer.concat(nline)
              end
              q.push [file_index, buffer, import_index]
              file_index += 1
              import_index += 1
            end
            q.push nil
          end

          th.map(&:join)
          ifp.close

          file_index
        end

        def execute_storage_detail(data, suffix)
          str = StringIO.new
          gz = Zlib::GzipWriter.new(str)
          gz.write data
          gz.close

          options = {
              content_type: 'application/x-gzip',
              bucket: @db_name,
              import: true
          }

          resource = ImportParameter.instance.url(suffix)
          @api.execute_storage(RestParameter.new(:put, resource, options)) do
            str.string
          end
        end

        class ImportParameter
          include Singleton

          attr_accessor :db_name, :tbl_name, :label, :index

          def initialize
            @index = 1
          end

          def url(suffix)
            "/#{@tbl_name}/#{@label}_#{suffix}.gz"
          end

          def object_label(suffix)
            "/#{@db_name}/#{@tbl_name}/#{@label}_#{suffix}.gz"
          end

          def file_label(suffix)
            "#{@label}_#{suffix}"
          end

          def storage_prefix
            "#{@tbl_name}/#{@label}"
          end
        end
      end

      class MultipartUpload
        def initialize(bucket, object, options = {}, &block)
          type = MIME::Types.type_for(object).first
          content_type = type ? type.to_s : 'application/octet-stream'
          options = options.merge(bucket: bucket, content_type: content_type)

          @bucket = bucket
          @object = object
          @splitsz = options.delete(:splitsz) || 100 * 1024 ** 2 #100MB
          @jobs = options.delete(:jobs) || 1
          @options = options
          @api = block[]
        end

        def initiate_multipart_upload
          STDERR.puts "Initiate multipart upload...\njobs:#{@jobs}, splitsz:#{@splitsz}"
          resource = "/#{@object}?uploads"
          response = @api.execute_storage(RestParameter.new(:post, resource, @options))
          upload_id = response.elements['InitiateMultipartUploadResult/UploadId'].text
          return upload_id
        end

        def upload_part(upload_id, &block)
          upload_objects = {}
          split_stream(upload_id, upload_objects, &block)
          return Hash[upload_objects.sort]
        end

        def complete_multipart_upload(upload_id, upload_objects)
          resource = "/#{@object}?uploadId=#{upload_id}"

          payload = '<CompleteMultipartUpload>'
          upload_objects.each do |part, etag|
            payload += "<Part><PartNumber>#{part}</PartNumber><ETag>#{etag}</ETag></Part>"
          end
          payload += '</CompleteMultipartUpload>'

          @api.execute_storage(RestParameter.new(:post, resource, @options)) do
            payload
          end

          puts "complete multipart upload."
        end

        def abort_multipart_upload(upload_id)
          resource = "/#{@object}?uploadId=#{upload_id}"
          @api.execute_storage(RestParameter.new(:delete, resource, @options))
        end

        private

        def split_stream(upload_id, upload_objects, &block)
          limit = 5 * 1024 ** 2 #5MB
          raise "split size is invalid. below lower limit of #{limit} byte" if @splitsz < limit

          ifp = block[]

          q = SizedQueue.new(@jobs)
          th = Array.new(@jobs) {
            Thread.new{
              while data = q.pop
                break unless data
                puts "> starting upload part #{data[0]}, #{data[1].length}"
                resource = "/#{@object}?partNumber=#{data[0]}&uploadId=#{upload_id}"
                response = @api.execute_storage(RestParameter.new(:put, resource, @options)) do
                  data[1]
                end
                puts "< finished upload part #{data[0]}, #{data[1].length}"
                upload_objects[data[0]] = response.headers['ETag'].first
              end
              q.push nil
            }
          }

          begin
            file_index = 1
            while true
              buffer = ifp.read(@splitsz)
              break unless buffer
              buffer.force_encoding("ASCII-8BIT")

              q.push [file_index, buffer]
              file_index += 1
            end
            q.push nil
          end

          th.map(&:join)
          puts "finished upload #{file_index-1} part objects."
        end
      end
    end
  end
end
