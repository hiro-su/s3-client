require 'pathname'
require 'simplecov'
require 'simplecov-rcov'
require 'spork'
require 'timecop'
require 'webmock/rspec'
require 'json'
require 'pry'
ENV['S3_CLIENT_ENV'] = 'test'

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 's3/client'
require 's3/client/exception'

Spork.prefork do
  SimpleCov.start do
      add_filter 'spec'
  end
  SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter

  RSpec.configure do |config|
    config.filter_run_excluding :integration => true
#      config.mock_with :nothing
      def capture(stream)
          begin
            stream = stream.to_s
            eval "$#{stream} = StringIO.new" #$stdout = StringIO.new
            yield
            result = eval("$#{stream}").string #eval ($stdout).string
          ensure
            eval("$#{stream} = #{stream.upcase}") #eval ($stdout = STDOUT)
          end
          result
      end
  end
end

Spork.each_run do
end
require 'shared_context'
