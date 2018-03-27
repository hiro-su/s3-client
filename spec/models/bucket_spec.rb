require 'spec_helper'

describe S3::Bucket do
  include_context "prepare_client"

  let(:api) { S3::Client::API.new(access_key_id, secret_access_key) }
  let(:bucket_name) { 'bucket' }
  let(:bucket) { S3::Bucket.new(api, bucket_name) }

  describe "#delete" do
    before do
      allow_any_instance_of(S3::Client::API).to receive(:delete_bucket)
    end

    it "should be successful" do
      bucket.delete
    end
  end

  describe "#name" do
    it "should return bucket name" do
      expect(bucket.name).to eq(bucket_name)
    end
  end

  describe "#objects" do
    it "should return S3::ObjectCollection" do
      expect(bucket.objects.class).to eq(S3::ObjectCollection)
    end
  end
end