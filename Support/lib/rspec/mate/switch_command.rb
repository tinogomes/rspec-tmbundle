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
      def content_for(twins_content_type, relative_path)
        case twins_content_type
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
      def content_type_of_twin(path)
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
      # * filepath          => ENV['TM_FILEPATH']
      #
      # TM_PROJECT_DIRECTORY (may not be set)
      #   the top-level folder in the project drawer
      #
      # TM_FILEPATH (may not be set)
      #   the current document's path (including file name)
      #
      # TODO: rename open_twin
      def go_to_twin(project_directory, filepath)
        twins_path = path_to_twin(filepath)

        open_twin(twins_path)
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

      # returns the path of the twin
      def path_to_twin(path)
        # $1 (framework) is the path up to lib, app or spec
        # $2 (parent) lib, app or spec
        # $3 (rest) is the rest of the path
        if path =~ /^(.*?)\/(lib|app|spec)\/(.*?)$/
          framework, parent, rest = $1, $2, $3
          framework.extend Framework

          case parent
            when 'lib', 'app' then
              if framework.merb_or_rails?
                # /app/ => /spec/
                path = path.gsub(/\/app\//, "/spec/")

                # /lib/ => /spec/lib/
                path = path.gsub(/\/lib\//, "/spec/lib/")
              else
                # /lib/ => /spec/
                path = path.gsub(/\/lib\//, "/spec/")
              end

              # suffix map
              # extensions = [.rb, .erb, .haml, .slim, .rhtml, .rjs]
              # extension => "#{extension}_spec.rb"
              path = path.gsub(/\.rb$/, "_spec.rb")
              path = path.gsub(/\.erb$/, ".erb_spec.rb")
              path = path.gsub(/\.haml$/, ".haml_spec.rb")
              path = path.gsub(/\.slim$/, ".slim_spec.rb")
              path = path.gsub(/\.rhtml$/, ".rhtml_spec.rb")
              path = path.gsub(/\.rjs$/, ".rjs_spec.rb")
            when 'spec' then
              # suffix map
              # extensions = [.rb, .erb, .haml, .slim, .rhtml, .rjs]
              # "#{extension}_spec.rb" => extension
              path = path.gsub(/\.rjs_spec\.rb$/, ".rjs")
              path = path.gsub(/\.rhtml_spec\.rb$/, ".rhtml")
              path = path.gsub(/\.erb_spec\.rb$/, ".erb")
              path = path.gsub(/\.haml_spec\.rb$/, ".haml")
              path = path.gsub(/\.slim_spec\.rb$/, ".slim")
              path = path.gsub(/_spec\.rb$/, ".rb")

              if framework.merb_or_rails?
                # /spec/lib/ => /lib/
                path = path.gsub(/\/spec\/lib\//, "/lib/")

                # /spec/ => /app/
                path = path.gsub(/\/spec\//, "/app/")
              else
                # /spec/ => /lib/
                path = path.gsub(/\/spec\//, "/lib/")
              end
          end

          return path
        end
      end


    private

      def class_name_from_path(path)
        underscored = path.split('/').last.split('.rb').first
        parts       = underscored.split('_')

        # words = File.basename(path_to_file, '.rb').split('_')

        parts.inject("") do |word, part|
          word << part.capitalize
          word
        end

        # words.inject("") do |class_name, word|
        #   class_name << word.capitalize
        #   class_name
        # end
      end

      def create?(relative_twin, twins_content_type)
        answer = `'#{ ENV['TM_SUPPORT_PATH'] }/bin/CocoaDialog.app/Contents/MacOS/CocoaDialog' yesno-msgbox --no-cancel --icon document --informative-text "#{relative_twin}" --text "Create missing #{twins_content_type}?"`

        answer.to_s.chomp == "1"
      end

      def open_twin(twins_path)
        if File.file?(twins_path)
          # open 'path_to_other' in textmate
          #
          # use backticks to do this
          %x{ "$TM_SUPPORT_PATH/bin/mate" "#{twins_path}" }
        else
          relative_path_from_project_dir_to_twin  = twins_path[project_directory.length + 1..-1]

          # returns one of: "filename" or "#filename spec" or "spec"
          twins_content_type = content_type_of_twin(twins_path)

          # create? is response to a dialog box, confirming creation of the
          # twin
          if create?(relative_path_from_project_dir_to_twin, twins_content_type)
            twins_content = content_for(twins_content_type, relative_path_from_project_dir_to_twin)

            write_and_open(twins_path, twins_content)
          end
        end
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
