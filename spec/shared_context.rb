RSpec.shared_context 'prepare_client' do
  let(:access_key_id) { 'access_key_id' }
  let(:secret_access_key) { 'secret_access_key' }
  let(:host) { 'http' }
  let(:client) { S3::Client.new(access_key_id, secret_access_key) }
  let(:authentication) { "AWS #{access_key_id}:signature" }
  let(:endpoint) { URI.parse(S3::Settings.endpoint) }
  let(:common_header) do
    {
      'Accept' => '*/*; q=0.5, application/xml',
      'Accept-Encoding' => 'gzip, deflate',
      'Authorization' => authentication,
      'Content-Length'=>0,
      'User-Agent' => "s3-client (#{S3::VERSION})",
      'Host' => "localhost:9292",
      'Date' => Time.now.httpdate
    }
  end

  before do
    Timecop.freeze(Time.parse('2014-08-21 14:00:00'))
    allow_any_instance_of(S3::Client::API::RestParameter).to receive(:authentication).and_return(authentication)
  end

  after do
    Timecop.return
  end
end
