require 'spec_helper'

describe S3::Client::API do
  include_context "prepare_client"
  let(:options) do
    {}
  end

  let(:api) { S3::Client::API.new(access_key_id, secret_access_key, options) }

  describe "#initialize" do
    context "when options key is valid" do
      let(:options) do
        {
          endpoint: 'http://localhost',
          location: 'localhost',
          force_path_style: true,
          debug: false,
        }
      end
      it { expect(api).to be_present }
    end

    context "when endpoint is invalid" do
      let(:options) do
        {
          endpoint: 'http://localhost/',
          location: 'localhost',
          force_path_style: true,
          debug: false,
        }
      end
      it { expect(api.endpoint).to eq('http://localhost/') }
    end

    context "when port number is added to endpoint url" do
      let(:options) do
        {
          endpoint: 'http://localhost:8080',
          location: 'localhost',
          force_path_style: true,
          debug: false,
        }
      end
      it { expect(api.endpoint).to eq('http://localhost:8080') }
    end

    RSpec.shared_examples 'raise api option invalid error' do
      it "エラーが発生すること" do
        expect {
          api
        }.to raise_error(S3::Client::APIOptionInvalid)
      end
    end

    context "when option key is invalid" do
      let(:options) do
        {
          endpoint_api: 'http://localhost',
        }
      end
      it "ArgumentErrorを投げる" do
        expect{
          api
        }.to raise_error(ArgumentError)
      end
    end

    context "when force_path_style is not boolean" do
      let(:options) do
        {
          force_path_style: 'hoge'
        }
      end
      it_behaves_like 'raise api option invalid error'
    end

    context "when force_path_style is not boolean" do
      let(:options) do
        {
          force_path_style: 'hoge'
        }
      end
      it_behaves_like 'raise api option invalid error'
    end

    context "when debug is not boolean" do
      let(:options) do
        {
          debug: 'hoge'
        }
      end
      it_behaves_like 'raise api option invalid error'
    end
  end

  describe "#execute_storage" do
    context "api return failure" do
      let(:url) { "#{S3::Settings.endpoint}/?storageManagement" }
      let(:status) { 404 }
      let(:code) { 'BucketNotFound' }
      let(:message) { "Couldn't find any storages for the bucket name." }

      before do
        stub_request(:any, url)
          .with(
            headers: common_header
          ).to_return(
            status: status,
            body: body,
            headers: {}
          )
      end

      context "when body is json response" do
        let(:body) {
          "{\"code\":\"#{code}\",\"message\":\"#{message}\",\"requestId\":\"DBFE220040C24841A54A3EF5352044A2\",\"resource\":\"/\",\"status\":#{status}}"
        }
        it 'should raise S3::APIFailure' do
          expect {
            api.execute_storage(S3::Client::API::RestParameter.new(:get, '/', cano_resource: 'storageManagement', raw_data: true))
          }.to raise_error(S3::Client::APIFailure) { |ex|
            response = JSON.parse(ex.api_message)
            expect(response['code']).to eq(code)
            expect(ex.api_status).to eq(status)
            expect(response['message']).to eq(message)
          }
        end
      end

      context "when body is xml response" do
        let(:body) {
          xml= <<XML
<?xml version="1.0" encoding="UTF-8"?>
<Error>
  <Code>#{code}</Code>
  <Message>#{message}</Message>
  <Resource>/mybucket/myfoto.jpg</Resource>
  <Status>404</Status>
  <RequestId>4442587FB7D0A2F9</RequestId>
</Error>
XML
          xml
        }
        it 'should raise S3::APIFailure' do
          expect {
            api.execute_storage(S3::Client::API::RestParameter.new(:get, '/', cano_resource: 'storageManagement'))
          }.to raise_error(S3::Client::APIFailure) { |ex|
            expect(ex.api_code).to eq(code)
            expect(ex.api_status).to eq(status)
            expect(ex.api_message).to eq(message)
          }
        end
      end
    end
  end

end