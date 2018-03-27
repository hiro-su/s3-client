require 'spec_helper'

describe S3::Client::API::RestParameter do
  let(:method) { :get }
  let(:host_uri) { URI.parse('http://localhost:3000') }
  let(:resource) { '/hoge' }
  let(:cano_resource) { 'storageManagement' }
  let(:content_type) { nil }
  let(:bucket) { nil }
  let(:query_params) do
    {
      :abc => 'def'
    }
  end

  let(:rest_parameter) do
    S3::Client::API::RestParameter.new(method, resource,
                                           cano_resource: cano_resource,
                                           query_params: query_params,
                                           bucket: bucket,
                                           content_type: content_type
                                          )
  end

  describe "#url" do
    let(:force_path_style) { false }
    subject { rest_parameter.url(host_uri, force_path_style) }
    it { is_expected.to eq('http://localhost:3000/hoge?storageManagement&abc=def') }

    context 'when bucket exists' do
      let(:bucket) { 'bucket' }
      it { is_expected.to eq('http://bucket.localhost:3000/hoge?storageManagement&abc=def') }

      context 'force_path_style is true ' do
        let(:force_path_style) { true }
        it { is_expected.to eq('http://localhost:3000/bucket/hoge?storageManagement&abc=def') }
      end
    end

    context 'cano_resource is nil' do
      let(:cano_resource) { nil }
      it { is_expected.to eq('http://localhost:3000/hoge?abc=def') }
    end

    context "when buckets api" do
      let(:resource) { '/' }
      let(:bucket) { nil }
      let(:cano_resource) { nil }
      let(:query_params) { nil }

      it { is_expected.to eq('http://localhost:3000/') }
    end

    context "when create bucket api" do
      let(:resource) { '/' }
      let(:bucket) { 'bucket' }
      let(:cano_resource) { nil }
      let(:query_params) { nil }

      it { is_expected.to eq('http://bucket.localhost:3000/') }

      context "force_path_style is true" do
        let(:force_path_style) { true }
        it { is_expected.to eq('http://localhost:3000/bucket/') }
      end
    end

    context "when create object api" do
      let(:resource) { '/object' }
      let(:bucket) { 'bucket' }
      let(:cano_resource) { nil }
      let(:query_params) { nil }

      it { is_expected.to eq('http://bucket.localhost:3000/object') }

      context "force_path_style is true" do
        let(:force_path_style) { true }
        it { is_expected.to eq('http://localhost:3000/bucket/object') }
      end
    end
  end

  describe "#http_verb" do
    subject { rest_parameter.http_verb }
    it { is_expected.to eq('GET') }
  end

  describe "#signature_content_type" do
    subject { rest_parameter.signature_content_type }

    it { is_expected.to eq("\n") }

    context "when method is put" do
      let(:method) { :post }
      let(:content_type) { 'application/json' }
      it { is_expected.to eq("#{content_type}\n") }
    end
  end

  describe "#authentication" do
    let(:access_key_id) { 'access_key_id' }
    let(:secret_access_key) { 'secret_access_key' }
    let(:force_path_style) { false }
    before do
      allow(rest_parameter).to receive(:signature).and_return('signature')
    end
    subject { rest_parameter.authentication(access_key_id, secret_access_key, force_path_style) }

    it { is_expected.to eq("AWS #{access_key_id}:signature") }
  end

  describe "#signature" do
    let(:secret_access_key) { 'secret_access_key' }
    subject { rest_parameter.signature(secret_access_key) }
    before do
      Timecop.freeze(Time.parse('2014-08-21 14:00:00'))
    end

    after do
      Timecop.return
    end

    it { is_expected.to eq('G7y55PRe1zFtPTEMjz9YB20AHTg=') }

    context "when method is post" do
      let(:method) { :post }
      let(:content_type) { 'application/json' }
      it { is_expected.to eq('2VIQat74ooVvFO8judU7t8FxrfY=') }
    end
  end

  describe "#canonicalized_resource" do
    let(:force_path_style) { false }
    subject { rest_parameter.canonicalized_resource(force_path_style) }
    it { is_expected.to eq('/hoge?storageManagement') }

    context 'when bucket exists' do
      let(:bucket) { 'bucket' }
      it { is_expected.to eq('/bucket/hoge?storageManagement') }
      context "and force_path_style is true" do
        let(:force_path_style) { true }
        it { is_expected.to eq('/bucket/hoge?storageManagement') }
      end
    end

    context 'when cano_resource is nil' do
      let(:cano_resource) { nil }
      it { is_expected.to eq('/hoge') }
    end

    context 'when bucket exists and cano_resource is nil' do
      let(:bucket) { 'bucket' }
      let(:cano_resource) { nil }
      it { is_expected.to eq('/bucket/hoge') }
      context "and force_path_style is true" do
        let(:force_path_style) { true }
        it { is_expected.to eq('/bucket/hoge') }
      end
    end

    context 'buckets api' do
      let(:resource) { '/' }
      let(:bucket) { nil }
      let(:cano_resource) { nil }
      let(:query_params) { nil }

      it { is_expected.to eq('/') }
    end

    context "when create bucket api" do
      let(:resource) { '/' }
      let(:bucket) { 'bucket' }
      let(:cano_resource) { nil }
      let(:query_params) { nil }

      it { is_expected.to eq('/bucket/') }

      context "force_path_style is true" do
        let(:force_path_style) { true }
        it { is_expected.to eq('/bucket/') }
      end
    end
  end
end