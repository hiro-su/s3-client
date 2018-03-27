require 'spec_helper'

describe S3::BucketCollection do
  include_context "prepare_client"

  let(:api) { S3::Client::API.new(access_key_id, secret_access_key) }
  let(:bucket_name) { 'bucket' }
  let(:bucket_collection) { S3::BucketCollection.new(api) }
  let(:buckets_result) { instance_double(S3::Concerns::BucketsResult) }
  let(:xml_doc) do
    result = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<ListAllMyBucketsResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
  <Buckets>
    <Bucket>
      <Name>bucket1</Name>
      <CreationDate>2018-03-26T06:31:29.000Z</CreationDate>
    </Bucket>
    <Bucket>
      <Name>bucket2</Name>
      <CreationDate>2018-03-26T06:31:29.000Z</CreationDate>
    </Bucket>
  </Buckets>
</ListAllMyBucketsResult>
XML
    REXML::Document.new(result)
  end

  describe "#each" do
    before do
      allow_any_instance_of(S3::Client::API).to receive(:buckets).and_return(xml_doc)
    end

    it "should return S3::Bucket" do
      bucket = bucket_collection.first
      expect(bucket.class).to eq(S3::Bucket)
      expect(bucket.name).to eq('bucket1')
    end
  end

  describe "#create" do
    before do
      allow_any_instance_of(S3::Client::API).to receive(:create_bucket)
    end

    it "should return S3::Bucket" do
      bucket = bucket_collection.create(bucket_name)
      expect(bucket.class).to eq(S3::Bucket)
    end
  end

  describe "#[]" do
    it "should return S3::Bucket" do
      bucket = bucket_collection[bucket_name]
      expect(bucket.class).to eq(S3::Bucket)
    end
  end
end