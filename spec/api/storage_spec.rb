require 'spec_helper'

describe S3::Client::API do
  include_context "prepare_client"
  let(:force_path_style) { false }
  let(:api) { S3::Client::API.new(access_key_id, secret_access_key, force_path_style: force_path_style, debug: true) }

  describe "#buckets" do
    let(:bucket) { 'quotes;' }
    let(:owner_id) { 'bcaf1ffd86f461ca5fb16fd081034f' }
    let(:xml) do
      result = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<ListAllMyBucketsResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
  <Owner>
    <ID>#{owner_id}</ID>
    <DisplayName>webfile</DisplayName>
  </Owner>
  <Buckets>
    <Bucket>
      <Name>#{bucket}</Name>
      <CreationDate>2006-02-03T16:45:09.000Z</CreationDate>
    </Bucket>
    <Bucket>
      <Name>samples</Name>
      <CreationDate>2006-02-03T16:41:58.000Z</CreationDate>
    </Bucket>
  </Buckets>
</ListAllMyBucketsResult>
XML
      result
    end

    before do
      common_header["Host"] = "#{endpoint.host}:#{endpoint.port}"
      stub_request(:get, "#{S3::Settings.endpoint}/")
        .with(
          headers: common_header
        ).to_return(
          status: 200,
          body: xml,
          headers: {}
        )
    end

    it "should return buckets" do
      buckets_result = S3::Concerns::BucketsResult.new(api.buckets)

      expect(buckets_result.owner_id).to eq(owner_id)
      expect(buckets_result.buckets.count).to eq(2)
      expect(buckets_result.buckets.first).to eq(bucket)
    end
  end

  describe "#objects" do
    let(:bucket) { 'bucket1' }
    let(:obj_1) { 'my-image.jpg' }
    let(:xml) do
      result =<<XML
<?xml version="1.0" encoding="UTF-8"?>
<ListBucketResult>
  <Name>bucket</Name>
  <Prefix/>
  <Marker/>
  <MaxKeys>1000</MaxKeys>
  <IsTruncated>false</IsTruncated>
  <Contents>
    <Key>#{obj_1}</Key>
    <LastModified>2009-10-12T17:50:30.000Z</LastModified>
    <ETag>&quot;fba9dede5f27731c9771645a39863328&quot;</ETag>
    <Size>434234</Size>
    <StorageClass>STANDARD</StorageClass>
    <Owner>
      <ID>8a6925ce4a7f21c32aa379004fef</ID>
      <DisplayName>mtd@#{endpoint.host}:#{endpoint.port}</DisplayName>
    </Owner>
  </Contents>
  <Contents>
    <Key>my-third-image.jpg</Key>
    <LastModified>2009-10-12T17:50:30.000Z</LastModified>
    <ETag>&quot;1b2cf535f27731c974343645a3985328&quot;</ETag>
    <Size>64994</Size>
    <StorageClass>STANDARD</StorageClass>
    <Owner>
      <ID>8a69b1ddee97f21c32aa379004fef</ID>
      <DisplayName>mtd@#{endpoint.host}:#{endpoint.port}</DisplayName>
    </Owner>
  </Contents>
</ListBucketResult>
XML

      result
    end

    before do
      stub_request(:get, "#{endpoint.scheme}://#{bucket}.#{endpoint.host}:#{endpoint.port}/")
        .with(
      headers: common_header.merge('Host' => "#{bucket}.#{endpoint.host}:#{endpoint.port}")
        ).to_return(
          status: 200,
          body: xml,
          headers: {}
        )
    end

    it "should return objects" do
      xml_doc = api.objects(bucket)
      objects_result = S3::Concerns::ObjectsResult.new(xml_doc)
      expect(objects_result.class).to eq(S3::Concerns::ObjectsResult)
      expect(objects_result.objects.first).to eq(obj_1)
    end
  end

  describe "#create_bucket" do
    let(:bucket) { 'bucket' }
    before do
      stub_request(:put, "#{endpoint.scheme}://#{bucket}.#{endpoint.host}:#{endpoint.port}/")
        .with(
          headers: common_header.merge(
            'Host' => "#{bucket}.#{endpoint.host}:#{endpoint.port}",
            'Content-Length' => '1',
          )
        ).to_return(
          status: 200,
          body: '',
          headers: {}
        )
    end

    it "should be succesful" do
      api.create_bucket(bucket)
    end
  end

  describe "#create_object" do
    let(:bucket) { 'bucket' }
    let(:object) { 'object_1' }
    before do
      stub_request(:put, "#{endpoint.scheme}://#{bucket}.#{endpoint.host}:#{endpoint.port}/#{object}")
        .with(
          headers: common_header.merge(
            'Host' => "#{bucket}.#{endpoint.host}:#{endpoint.port}",
            'Content-Length' => '15'
          )
        ).to_return(
          status: 200,
          body: '',
          headers: {}
        )
    end

    it "should be succesful" do
      api.create_object(bucket, object) do
        "aaaaaaaaaaaaaaa"
      end
    end
  end

  describe "#get_object" do
    let(:bucket) { 'bucket' }
    let(:object) { 'object_1' }
    let(:body) { 'abcdef' }
    before do
      stub_request(:get, "#{endpoint.scheme}://#{bucket}.#{endpoint.host}:#{endpoint.port}/#{object}")
        .with(
          headers: common_header.merge('Host' => "#{bucket}.#{endpoint.host}:#{endpoint.port}")
        ).to_return(
          status: 200,
          body: body,
          headers: {}
        )
    end

    it "should be succesful" do
      result = api.get_object(bucket, object)
      expect(result).to eq(body)
    end
  end

  describe "#delete_bucket" do
    let(:bucket) { 'bucket' }
    before do
      stub_request(:delete, "#{endpoint.scheme}://#{bucket}.#{endpoint.host}:#{endpoint.port}/")
        .with(
          headers: common_header.merge('Host' => "#{bucket}.#{endpoint.host}:#{endpoint.port}")
        ).to_return(
          status: 200,
          body: '',
          headers: {}
        )
    end

    it "should be succesful" do
      api.delete_bucket(bucket)
    end
  end

  describe "#delete_object" do
    let(:bucket) { 'bucket' }
    let(:object) { 'object2' }
    before do
      stub_request(:delete, "#{endpoint.scheme}://#{bucket}.#{endpoint.host}:#{endpoint.port}/#{object}")
        .with(
          headers: common_header.merge('Host' => "#{bucket}.#{endpoint.host}:#{endpoint.port}")
        ).to_return(
          status: 200,
          body: '',
          headers: {}
        )
    end

    it "should be succesful" do
      api.delete_object(bucket, object)
    end
  end

  describe "import" do
    let(:db_name) { 'db' }
    let(:table) { 'table' }
    let(:label) { 'abc' }

    before do
      stub_request(:get, "#{endpoint.scheme}://#{db_name}.#{endpoint.host}:#{endpoint.port}/?prefix=#{table}/#{label}")
        .with(
          headers: common_header.merge('Host' => "#{db_name}.#{endpoint.host}:#{endpoint.port}")
        ).to_return(
          status: 200,
          body: '',
          headers: {}
        )
      stub_request(:put, "#{endpoint.scheme}://#{db_name}.#{endpoint.host}:#{endpoint.port}/#{table}/#{label}_0.gz")
    end

    context "when file is .txt" do
      let(:file_path) { 'spec/sample/import2.json' }
      it "should success uploading" do
        api.import(db_name, table, file_path, jobs: 1, label: label)
      end
    end

    context "when file is .gz" do
      let(:file_path) { 'spec/sample/import.gz' }
      it "should success uploading" do
        api.import(db_name, table, file_path, jobs: 1, label: label)
      end
    end

    context "when file is .txt and .gz" do
      before do
        allow_any_instance_of(Thread).to receive(:join).and_return(nil)
      end

      let(:file_path) { ['spec/sample/import2.json', 'spec/sample/import.gz'] }
      it "should success uploading" do
        api.import(db_name, table, file_path, jobs: 1, label: label)
      end
    end
  end

  describe "#calc_label_suffix" do
    let(:db_name) { 'db' }
    let(:tbl_name) { 'tbl' }
    let(:file_paths) { ['file1', 'file2'] }
    let(:jobs) { 1 }
    let(:label) { 'label' }

    let(:import) { S3::Client::API::Storage::Import.new(db_name, tbl_name, file_paths, jobs: jobs, label: label) { api } }
    let(:import_parameter) { import.ImportParameter.instance }
    let(:objects_result) { instance_double(S3::Concerns::ObjectsResult) }

    let(:xml_doc) do
      result = <<XML
<ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
  <Prefix></Prefix>
  <Marker></Marker>
  <MaxKeys>1000</MaxKeys>
  <IsTruncated>false</IsTruncated>
  <Contents>
    <Key>label_1</Key>
    <LastModified>2018-03-26T19:05:36.000Z</LastModified>
    <ETag>&quot;d41d8cd98f00b204e9800998ecf8427e&quot;</ETag>
    <Size>0</Size>
  </Contents>
  <Contents>
    <Key>label_2</Key>
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

    it "should return 3" do
      expect(import.send(:calc_label_suffix)).to eq(3)
    end

    context "when objects is blank" do
      let(:xml_doc) do
        result = <<XML
<ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
  <Prefix></Prefix>
  <Marker></Marker>
  <MaxKeys>1000</MaxKeys>
  <IsTruncated>false</IsTruncated>
</ListBucketResult>
XML
        REXML::Document.new(result)
      end

      it "should return 0" do
        expect(import.send(:calc_label_suffix)).to eq(0)
      end
    end

    context "when objects include 11" do
      let(:xml_doc) do
        result = <<XML
<ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
  <Prefix></Prefix>
  <Marker></Marker>
  <MaxKeys>1000</MaxKeys>
  <IsTruncated>false</IsTruncated>
  <Contents>
    <Key>label_11</Key>
    <LastModified>2018-03-26T19:05:36.000Z</LastModified>
    <ETag>&quot;d41d8cd98f00b204e9800998ecf8427e&quot;</ETag>
    <Size>0</Size>
  </Contents>
</ListBucketResult>
XML
        REXML::Document.new(result)
      end

      it "should return 12" do
        expect(import.send(:calc_label_suffix)).to eq(12)
      end
    end

    context "when object includes gz extension" do
      let(:xml_doc) do
        result = <<XML
<ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
  <Prefix></Prefix>
  <Marker></Marker>
  <MaxKeys>1000</MaxKeys>
  <IsTruncated>false</IsTruncated>
  <Contents>
    <Key>label_1.gz</Key>
    <LastModified>2018-03-26T19:05:36.000Z</LastModified>
    <ETag>&quot;d41d8cd98f00b204e9800998ecf8427e&quot;</ETag>
    <Size>0</Size>
  </Contents>
  <Contents>
    <Key>label_11.gz</Key>
    <LastModified>2018-03-26T19:05:36.000Z</LastModified>
    <ETag>&quot;d41d8cd98f00b204e9800998ecf8427e&quot;</ETag>
    <Size>0</Size>
  </Contents>
  <Contents>
    <Key>label_2.gz</Key>
    <LastModified>2018-03-26T19:05:36.000Z</LastModified>
    <ETag>&quot;d41d8cd98f00b204e9800998ecf8427e&quot;</ETag>
    <Size>0</Size>
  </Contents>
</ListBucketResult>
XML
        REXML::Document.new(result)
      end

      it "should return 12" do
        expect(import.send(:calc_label_suffix)).to eq(12)
      end
    end
  end
end