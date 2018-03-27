#!/usr/bin/env ruby

require 'bundler/setup'
require 's3/client'

# create client
access_key_id = ENV['AWS_ACCESS_KEY_ID']
secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']
client = S3::Client.new(access_key_id, secret_access_key, debug: false, force_path_style: false)

# buckets
client.buckets.each do |bucket|
  bucket.objects.each do |object|
    puts "#{bucket.name}/#{object.name}"
  end
end
