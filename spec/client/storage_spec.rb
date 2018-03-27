require 'spec_helper'

describe S3::Client do
  include_context "prepare_client"

  describe "#buckets" do
    let(:buckets_result) { instance_double(S3::Bucket) }
    let(:buckets) do
      [
        'abc',
        'def'
      ]
    end
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


    before do
      allow_any_instance_of(S3::Client::API).to receive(:buckets).and_return(xml_doc)
    end

    it "should return bucket collection" do
      results = client.buckets
      expect(results.class).to eq(S3::BucketCollection)
      expect(results.first.class).to eq(S3::Bucket)
      expect(results.first.name).to eq('bucket1')
    end
  end

  describe "#objects" do
    let(:full_objects) do
      [
        {"Key"=>['label1']},
        {"Key"=>['label2']}
      ]
    end
    let(:bucket) { 'bucket1' }
    let(:objects_result) { instance_double(S3::Object) }
    let(:xml_doc) do
      result = <<XML
<ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
  <Prefix></Prefix>
  <Marker></Marker>
  <MaxKeys>1000</MaxKeys>
  <IsTruncated>false</IsTruncated>
  <Contents>
    <Key>label1</Key>
    <LastModified>2018-03-26T19:05:36.000Z</LastModified>
    <ETag>&quot;d41d8cd98f00b204e9800998ecf8427e&quot;</ETag>
    <Size>0</Size>
  </Contents>
  <Contents>
    <Key>label2</Key>
    <LastModified>2018-03-26T19:05:36.000Z</LastModified>
    <ETag>&quot;d41d8cd98f00b204e9800998ecf8427e&quot;</ETag>
    <Size>0</Size>
  </Contents>
</ListBucketResult>
XML
      REXML::Document.new(result)
    end

    before do
      allow_any_instance_of(S3::Client::API).to receive(:objects).and_return(xml_doc)
    end

    it "should return objects collection" do
      objects = client.objects(bucket)
      expect(objects.class).to eq(S3::ObjectCollection)
      expect(objects.first.class).to eq(S3::Object)
    end
  end

  describe "#create_bucket" do
    before do
      allow_any_instance_of(S3::Client::API).to receive(:create_bucket)
    end

    it "should return S3::Bucket" do
      bucket = client.create_bucket('bucket')
      expect(bucket.class).to eq(S3::Bucket)
    end
  end

  describe "#delete_bucket" do
    before do
      allow_any_instance_of(S3::Client::API).to receive(:delete_bucket)
    end

    it "should return nil" do
      expect(client.delete_bucket('bucket1')).to be_nil
    end
  end

  describe "#delete_object" do
    before do
      allow_any_instance_of(S3::Client::API).to receive(:delete_object)
    end

    it "should return S3::Object" do
      expect(client.delete_object('bucket', 'object')).to be_nil
    end
  end

  describe "#import" do
    before do
      allow_any_instance_of(S3::Client::API).to receive(:import)
    end

    it "should return S3::Object" do
      expect(client.import('bucket', 'object', ['log/log1.gz', 'log/log2.gz'])).to be_nil
    end
  end
end