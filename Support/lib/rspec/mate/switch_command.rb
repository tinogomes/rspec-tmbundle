module RSpec
  module Mate
    # Based on Ruy Asan's initial code.
    class SwitchCommand
      module Framework
        def merb?
          File.exist?(File.join(self, 'config', 'init.rb'))
        end

        def merb_or_rails?
          merb? || rails?
        end

        def rails?
          File.exist?(File.join(self, 'config', 'boot.rb'))
        end
      end

      # public only for testing purposes
      def content_for(file_type, relative_path)
        case file_type
          when /spec$/ then
            spec(relative_path)
          when "controller"
            <<-CONTROLLER
class #{class_name_from_path(relative_path)} < ApplicationController
end
CONTROLLER
          when "model"
            <<-MODEL
class #{class_name_from_path(relative_path)} < ActiveRecord::Base
end
MODEL
          when "helper"
            <<-HELPER
module #{class_name_from_path(relative_path)}
end
HELPER
          when "view"
            ""
          else
            klass(relative_path)
        end
      end

      # path contains app/(controllers|helpers|models|views)/(.*?)
      def file_type(path)
        # $1 contains the path from '/' to the 'app' directory
        # $2 contains immediate subdirectory to 'app'
        # $3 contains the path relative to spec/$2/

        # $3[0..-2] is the filename with the extension removed
        if path =~ /^(.*?)\/(spec)\/(controllers|helpers|models|views)\/(.*?)$/
          return "#{$3[0..-2]} spec"
        end

        if path =~ /^(.*?)\/(app)\/(controllers|helpers|models|views)\/(.*?)$/
          return $3[0..-2]
        end

        if path =~ /_spec\.rb$/
          return "spec"
        end

        "file"
      end

      # primary method used
      #
      # * project_directory => ENV['TM_PROJECT_DIRECTOR']
      # * filepath => ENV['TM_FILEPATH']
      #
      # TM_PROJECT_DIRECTORY
      #   the top-level folder in the project drawer (may not be set).
      #
      # TM_FILEPATH
      #   the path (including file name) for the current document
      #   (may not be set).
      def go_to_twin(project_directory, filepath)
        # TODO: twin renamed path_to_other
        #
        # twin returns the path of the twin
        other = twin(filepath)

        # File.exsits(path_to_other)
        if File.file?(other)
          # open 'path_to_other' in textmate
          #
          # use backticks to do this
          %x{ "$TM_SUPPORT_PATH/bin/mate" "#{other}" }
        else
          # what is this doing?
          relative  = other[project_directory.length+1..-1]

          # file_type returns "filename" or "#filename spec" or "spec"
          file_type = file_type(other)

          # create? is response to a dialog box, confirming creation of the
          # path_to_other file
          if create?(relative, file_type)
            content = content_for(file_type, relative)
            write_and_open(other, content)
          end
        end
      end

      # TODO: provide an intention revealing name path_to_class_content
      def klass(relative_path, content=nil)
        parts     = relative_path.split('/')
        lib_index = parts.index('lib') || 0
        parts     = parts[lib_index+1..-1]
        lines     = Array.new(parts.length*2)

        parts.each_with_index do |part, n|
          part   = part.capitalize
          indent = "  " * n

          line = if part =~ /(.*)\.rb/
            part = $1
            "#{indent}class #{part}"
          else
            "#{indent}module #{part}"
          end

          lines[n] = line
          lines[lines.length - (n + 1)] = "#{indent}end"
        end

        lines.join("\n") + "\n"
      end

      def twin(path)
        if path =~ /^(.*?)\/(lib|app|spec)\/(.*?)$/
          framework, parent, rest = $1, $2, $3
          framework.extend Framework

          case parent
            when 'lib', 'app' then
              if framework.merb_or_rails?
                path = path.gsub(/\/app\//, "/spec/")
                path = path.gsub(/\/lib\//, "/spec/lib/")
              else
                path = path.gsub(/\/lib\//, "/spec/")
              end

              path = path.gsub(/\.rb$/, "_spec.rb")
              path = path.gsub(/\.erb$/, ".erb_spec.rb")
              path = path.gsub(/\.haml$/, ".haml_spec.rb")
              path = path.gsub(/\.slim$/, ".slim_spec.rb")
              path = path.gsub(/\.rhtml$/, ".rhtml_spec.rb")
              path = path.gsub(/\.rjs$/, ".rjs_spec.rb")
            when 'spec' then
              path = path.gsub(/\.rjs_spec\.rb$/, ".rjs")
              path = path.gsub(/\.rhtml_spec\.rb$/, ".rhtml")
              path = path.gsub(/\.erb_spec\.rb$/, ".erb")
              path = path.gsub(/\.haml_spec\.rb$/, ".haml")
              path = path.gsub(/\.slim_spec\.rb$/, ".slim")
              path = path.gsub(/_spec\.rb$/, ".rb")

              if framework.merb_or_rails?
                path = path.gsub(/\/spec\/lib\//, "/lib/")
                path = path.gsub(/\/spec\//, "/app/")
              else
                path = path.gsub(/\/spec\//, "/lib/")
              end
          end

          return path
        end
      end


    private

      def class_name_from_path(path)
        underscored = path.split('/').last.split('.rb').first
        parts = underscored.split('_')

        parts.inject("") do |word, part|
          word << part.capitalize
          word
        end
      end

      def create?(relative_twin, file_type)
        answer = `'#{ ENV['TM_SUPPORT_PATH'] }/bin/CocoaDialog.app/Contents/MacOS/CocoaDialog' yesno-msgbox --no-cancel --icon document --informative-text "#{relative_twin}" --text "Create missing #{file_type}?"`
        answer.to_s.chomp == "1"
      end

      # Extracts the snippet text
      def snippet(snippet_name)
        snippet_file = File.expand_path(
          File.dirname(__FILE__) +
          "/../../../../Snippets/#{snippet_name}"
        )

        xml = File.open(snippet_file).read

        xml.match(/<key>content<\/key>\s*<string>([^<]*)<\/string>/m)[1]
      end

      def spec(path)
        content = <<-SPEC
require 'spec_helper'

#{snippet("Describe_type.tmSnippet")}
SPEC
      end

      def write_and_open(path, content)
        `mkdir -p "#{File.dirname(path)}"`
        `touch "#{path}"`
        `"$TM_SUPPORT_PATH/bin/mate" "#{path}"`
        `osascript &>/dev/null -e 'tell app "SystemUIServer" to activate' -e 'tell app "TextMate" to activate'`

        escaped_content = content.gsub("\n","\\n").gsub('$','\\$').gsub('"','\\\\\\\\\\\\"')

        `osascript &>/dev/null -e "tell app \\"TextMate\\" to insert \\"#{escaped_content}\\" as snippet true"`
      end
    end
  end
end
