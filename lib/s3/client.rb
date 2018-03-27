require 'driver'
require 's3/settings'
require 's3/version'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/object/try'
require 'active_support/core_ext/object/to_query'

module S3
  class Client < Driver::Client
    drive Storage

    # Constructor
    # @param [String] access_key_id AccessKeyId
    # @param [String] secret_access_key SecretAccessKey
    # @param [Hash] options Options
    def initialize(access_key_id, secret_access_key, **options)
      require 's3/client/exception'
      require 'ostruct'

      @api = API.new(access_key_id, secret_access_key, options)

      self
    end

    attr_reader :api

    require "forwardable"
    extend Forwardable
    def_delegators :@api, *%w(access_key_id secret_access_key endpoint).flat_map { |a| [a, a+?=] }.map(&:intern)
  end
end
