require 'spec_helper'

describe S3::Object do
  include_context "prepare_client"

  let(:api) { S3::Client::API.new(access_key_id, secret_access_key) }
  let(:bucket_name) { 'bucket' }
  let(:object_name) { 'object' }
  let(:object) { S3::Object.new(api, bucket_name, object_name) }

  describe "#name" do
    it "should return object_name" do
      expect(object.name).to eq(object_name)
    end
  end

  describe "#read" do
    let(:read_detail) { 'abcdefg' }
    before do
      allow_any_instance_of(S3::Client::API).to receive(:get_object).and_return(read_detail)
    end

    it "should return object detail" do
      expect(object.read).to eq(read_detail)
    end
  end

  describe "#write" do
    before do
      allow_any_instance_of(S3::Client::API).to receive(:create_object)
    end

    subject { object.write(target) }

    context "when target is string" do
      let(:target) { 'abcdef' }

      it { is_expected.to be_nil }
    end

    context "when target is pathname" do
      let(:target) { Pathname.new('spec/sample/import.json') }

      it { is_expected.to be_nil }
    end

    context "when target is file" do
      let(:target) { File.open('spec/sample/import.json') }

      it { is_expected.to be_nil }
    end
  end
end
