# This is based on Florian Weber's TDDMate

ENV['TM_PROJECT_DIRECTORY'] ||= File.dirname(ENV['TM_FILEPATH'])

def has_spec_autorun?(directory)
  File.exists?(File.join(directory, %w(spec autorun.rb)))
end

# Load spec/autorun
if File.exist?(File.join(ENV['TM_PROJECT_DIRECTORY'], 'Gemfile'))
  require "rubygems"
  require "bundler"
  Bundler.setup
else
  # Find it the old-fashioned way: in vendor/plugins, or in vendor/gems, 
  # or at TM_RSPEC_HOME
  rspec_locs = Dir.glob(File.join(ENV['TM_PROJECT_DIRECTORY'],'vendor','{plugins,gems}','rspec{,-[0-9]*}', 'lib'))
  rspec_locs << File.join(ENV['TM_RSPEC_HOME'], 'lib') if ENV['TM_RSPEC_HOME']
  rspec_root = rspec_locs.reject { |dir| !has_spec_autorun?(dir) }.first

  if rspec_root
    $LOAD_PATH.unshift(rspec_root)
  elsif ENV['TM_RSPEC_HOME']
    raise "TM_RSPEC_HOME points to a bad location: #{ENV['TM_RSPEC_HOME']}" unless File.directory?(File.join(ENV['TM_RSPEC_HOME'], 'lib'))
  end
end

begin
  require 'spec/autorun'
rescue LoadError
  require 'rspec/core'
end

def rspec2?
  defined?(RSpec)
end

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/..')
require 'spec/mate/runner'
require 'spec/mate/switch_command'
