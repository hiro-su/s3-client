require 'spec_helper'
require 'open3'

=begin
describe 'sample' do
  RSpec.shared_examples 'sample_from_command' do
    it "エラーが発生しないこと" do
      _, e, _ = Open3.capture3("bundle exec ruby sample/#{file_name}")
      expect(e).to be_blank
    end
  end

  describe 'test.rb' do
    let(:file_name) { 'test.rb' }

    it_behaves_like 'sample_from_command'
  end
end
=end