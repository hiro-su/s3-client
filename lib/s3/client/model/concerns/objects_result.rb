module S3
  class Concerns
    class ObjectsResult < Driver::Model
      def initialize(xml_doc)
        @xml_doc = xml_doc
      end

      def objects
        REXML::XPath.match(@xml_doc, "/ListBucketResult/Contents/Key").map { |b| b.text }
      end

      def full_objects
        REXML::XPath.match(@xml_doc, "/ListBucketResult/Contents").map{|m|
          XmlSimple.xml_in(m.to_s)
        }
      end

      def truncated?
        REXML::XPath.match(@xml_doc, "/ListBucketResult/IsTruncated").map { |b| b.text }.first == 'true'
      end

      def marker
        REXML::XPath.match(@xml_doc, "/ListBucketResult/Marker").map { |b| b.text }.first
      end

      def next_marker
        REXML::XPath.match(@xml_doc, "/ListBucketResult/NextMarker").map { |b| b.text }.first
      end

      def max
        REXML::XPath.match(@xml_doc, "/ListBucketResult/MaxKeys").map { |b| b.text }.first.to_i
      end
    end
  end
end
