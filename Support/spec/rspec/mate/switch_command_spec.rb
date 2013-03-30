require 'spec_helper'

module RSpec
  module Mate
    describe SwitchCommand do
      class << self
        def expect_others(pair)
          specify do
            pair[0].should other(pair[1])
          end
        end
      end

      RSpec::Matchers.define :other do |*args|
        expected = args.shift
        opts     = args.last || {:webapp => false}

        File.stub!(:exist?).and_return(opts[:webapp])

        match do |actual|
          command = SwitchCommand.new
          command.path_to_other(actual) == expected &&
            command.path_to_other(expected) == actual
        end
      end

      RSpec::Matchers.define :be_a do |expected|
        match do |actual|
          SwitchCommand.new.content_type_of_other(actual) == expected
        end
      end

      describe "in a regular app" do
        expect_others [
          "/Users/aslakhellesoy/scm/rspec/trunk/RSpec.tmbundle/Support/spec/rspec/mate/switch_command_spec.rb",
          "/Users/aslakhellesoy/scm/rspec/trunk/RSpec.tmbundle/Support/lib/rspec/mate/switch_command.rb"
        ]

        it "suggest a plain spec" do
          "/a/full/path/spec/snoopy/mooky_spec.rb".should be_a("spec")
        end

        it "suggests a plain file" do
          "/a/full/path/lib/snoopy/mooky.rb".should be_a("file")
        end

        it "create a spec for spec files" do
          regular_spec = <<-SPEC
require 'spec_helper'

describe ${1:Type} do
  $0
end
SPEC
          SwitchCommand.new.content_for(
            "spec/foo/zap_spec.rb",
            'spec'
          ).should == regular_spec

          SwitchCommand.new.content_for(
            "spec/controller/zap_spec.rb",
            'spec'
          ).should == regular_spec
        end

        it "create class for regular file" do
          file = <<-EOF
module Foo
  class Zap
  end
end
EOF
          SwitchCommand.new.content_for(
            "lib/foo/zap.rb",
            'file'
          ).should == file

          SwitchCommand.new.content_for(
            "some/other/path/lib/foo/zap.rb",
            'file'
          ).should == file
        end
      end

      describe "in a Rails or Merb app" do
        def other(expected)
          super(expected, :webapp => true)
        end

        expect_others [
          "/a/full/path/app/controllers/mooky_controller.rb",
          "/a/full/path/spec/controllers/mooky_controller_spec.rb"
        ]

        expect_others [
          "/a/full/path/app/controllers/application_controller.rb",
          "/a/full/path/spec/controllers/application_controller_spec.rb"
        ]

        expect_others [
          "/a/full/path/spec/controllers/application_controller_spec.rb",
          "/a/full/path/app/controllers/application_controller.rb"
        ]

        expect_others [
          "/a/full/path/app/controllers/job_applications_controller.rb",
          "/a/full/path/spec/controllers/job_applications_controller_spec.rb"
        ]

        expect_others [
          "/a/full/path/spec/controllers/job_applications_controller_spec.rb",
          "/a/full/path/app/controllers/job_applications_controller.rb"
        ]

        expect_others [
          "/a/full/path/app/helpers/application_helper.rb",
          "/a/full/path/spec/helpers/application_helper_spec.rb"
        ]

        expect_others [
          "/a/full/path/spec/helpers/application_helper_spec.rb",
          "/a/full/path/app/helpers/application_helper.rb"
        ]

        expect_others [
          "/a/full/path/app/models/mooky.rb",
          "/a/full/path/spec/models/mooky_spec.rb"
        ]

        expect_others [
          "/a/full/path/app/helpers/mooky_helper.rb",
          "/a/full/path/spec/helpers/mooky_helper_spec.rb"
        ]

        expect_others [
          "/a/full/path/app/views/mooky/show.html.erb",
          "/a/full/path/spec/views/mooky/show.html.erb_spec.rb"
        ]

        expect_others [
          "/a/full/path/app/views/mooky/show.html.haml",
          "/a/full/path/spec/views/mooky/show.html.haml_spec.rb"
        ]

        expect_others [
          "/a/full/path/app/views/mooky/show.html.slim",
          "/a/full/path/spec/views/mooky/show.html.slim_spec.rb"
        ]

        expect_others [
          "/a/full/path/app/views/mooky/show.rhtml",
          "/a/full/path/spec/views/mooky/show.rhtml_spec.rb"
        ]

        expect_others [
          "/a/full/path/app/views/mooky/show.js.rjs",
          "/a/full/path/spec/views/mooky/show.js.rjs_spec.rb"
        ]

        expect_others [
          "/a/full/path/app/views/mooky/show.rjs",
          "/a/full/path/spec/views/mooky/show.rjs_spec.rb"
        ]

        expect_others [
          "/a/full/path/lib/foo/mooky.rb",
          "/a/full/path/spec/lib/foo/mooky_spec.rb"
        ]

        it "suggests a controller spec" do
          "/a/full/path/spec/controllers/mooky_controller_spec.rb".should be_a("controller spec")
        end

        it "suggests a model spec" do
          "/a/full/path/spec/models/mooky_spec.rb".should be_a("model spec")
        end

        it "suggests a helper spec" do
          "/a/full/path/spec/helpers/mooky_helper_spec.rb".should be_a("helper spec")
        end

        it "suggests a view spec for erb" do
          "/a/full/path/spec/views/mooky/show.html.erb_spec.rb".should be_a("view spec")
        end

        it "suggests a view spec for haml" do
          "/a/full/path/spec/views/mooky/show.html.haml_spec.rb".should be_a("view spec")
        end

        it "suggests a view spec for slim" do
          "/a/full/path/spec/views/mooky/show.html.slim_spec.rb".should be_a("view spec")
        end

        it "suggests an rjs view spec" do
          "/a/full/path/spec/views/mooky/show.js.rjs_spec.rb".should be_a("view spec")
        end

        it "suggests a controller" do
          "/a/full/path/app/controllers/mooky_controller.rb".should be_a("controller")
        end

        it "suggests a model" do
          "/a/full/path/app/models/mooky.rb".should be_a("model")
        end

        it "suggests a helper" do
          "/a/full/path/app/helpers/mooky_helper.rb".should be_a("helper")
        end

        it "suggests a view" do
          "/a/full/path/app/views/mooky/show.html.erb".should be_a("view")
        end

        it "suggests an rjs view" do
          "/a/full/path/app/views/mooky/show.js.rjs".should be_a("view")
        end

        it "create a spec that requires a helper" do
          SwitchCommand.new.content_for(
            "spec/controllers/mooky_controller_spec.rb",
            'controller spec'
          ).split("\n")[0].should == "require 'spec_helper'"
        end

        it "creates a controller if othered from a controller spec" do
          SwitchCommand.new.content_for(
            "spec/controllers/mooky_controller.rb",
            'controller'
          ).should == <<-EXPECTED
class MookyController < ApplicationController
end
EXPECTED
        end

        it "creates a model if othered from a model spec" do
          SwitchCommand.new.content_for(
            "spec/models/mooky.rb",
            'model'
          ).should == <<-EXPECTED
class Mooky < ActiveRecord::Base
end
EXPECTED
        end

        it "creates a helper if othered from a helper spec" do
          SwitchCommand.new.content_for(
            "spec/helpers/mooky_helper.rb",
            'helper'
          ).should == <<-EXPECTED
module MookyHelper
end
EXPECTED
        end

        it "creates an empty view if othered from a view spec" do
          SwitchCommand.new.content_for(
            "spec/views/mookies/index.html.erb_spec.rb",
            'view'
          ).should == ""
        end
      end
    end
  end
end
