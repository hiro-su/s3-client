require 'spec_helper'

describe S3::ObjectCollection do
  include_context "prepare_client"

  let(:api) { S3::Client::API.new(access_key_id, secret_access_key) }
  let(:bucket_name) { 'bucket' }
  let(:object_collection) { S3::ObjectCollection.new(api, bucket_name) }
  let(:objects_result) { instance_double(S3::Concerns::ObjectsResult) }
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

  describe "#each" do
    before do
      allow_any_instance_of(S3::Client::API).to receive(:objects).and_return(xml_doc)
    end

    it "should return S3::Object" do
      object = object_collection.first
      expect(object.class).to eq(S3::Object)
      expect(object.name).to eq('label1')
    end
  end

  describe "#[]" do
    it "should return S3::Object" do
      object = object_collection['label1']
      expect(object.class).to eq(S3::Object)
    end
  end
end
