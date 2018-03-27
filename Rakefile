# -*- encoding: utf-8 -*-
#
#require "bundler/setup"

# gem install tasks, but remove "release"
#Rake::Task[:release].clear

#$:.unshift File.expand_path("../lib", __FILE__)
require 'bundler/gem_tasks'
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)
task :default => :spec


task :doc => "document:build"

namespace :spec do
  [:api, :client, :models].each do |dir|
    desc "Run #{dir} spec"
    RSpec::Core::RakeTask.new(dir) do |t|
      t.pattern = "spec/#{dir}/*_spec.rb"
    end
  end

  task :without_sample => ['spec:api', 'spec:client', 'spec:models']
end

namespace :document do
  task :build do
    docpath = "../documents/parser"
    if Dir.exist? docpath
      pid = spawn("yard", "-o", docpath, STDERR => STDOUT)
      Process.waitpid pid
    else
      puts "You don't have #{docpath} directory."
      puts "Can't create a new document."
    end
  end
end
