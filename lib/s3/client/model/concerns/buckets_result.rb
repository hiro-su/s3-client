module S3
  class Concerns
    class BucketsResult < Driver::Model
      def initialize(xml_doc)
        @xml_doc = xml_doc
      end

      def buckets
        REXML::XPath.match(@xml_doc, "/ListAllMyBucketsResult/Buckets/Bucket/Name").map { |b| b.text }
      end

      def owner_id
        REXML::XPath.match(@xml_doc, "/ListAllMyBucketsResult/Owner/ID").map { |b| b.text }.first
      end

      def owner_display_name
        REXML::XPath.match(@xml_doc, "/ListAllMyBucketsResult/Owner/DisplayName").map { |b| b.text }.first
      end
    end
  end
end