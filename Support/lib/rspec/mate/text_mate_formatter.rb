require 'cgi'
require 'rspec/core/formatters/html_formatter'

module RSpec
  module Mate
    module Formatters
      # Formats backtraces so they're clickable by TextMate
      class TextMateFormatter < RSpec::Core::Formatters::HtmlFormatter
        def backtrace_line(line, skip_textmate_conversion=false)
          if skip_textmate_conversion
            super(line)
          else
            format_backtrace_line_for_textmate(super(line))
          end
        end

        def format_backtrace_line_for_textmate(line)
          return nil unless line
          CGI.escapeHTML(line).sub(/([^:]*\.e?rb):(\d*)/) do
            "<a href=\"txmt://open?url=file://#{File.expand_path($1)}&line=#{$2}\">#{$1}:#{$2}</a> "
          end
        end

        def extra_failure_content(exception)
          require 'rspec/core/formatters/snippet_extractor'
          backtrace = exception.backtrace.map {|line| backtrace_line(line, :skip_textmate_conversion)}
          backtrace.compact!
          @snippet_extractor ||= RSpec::Core::Formatters::SnippetExtractor.new
          "    <pre class=\"ruby\"><code>#{@snippet_extractor.snippet(backtrace)}</code></pre>"
        end
        
        def example_failed(example)
          # super(example)

          unless @header_red
            @header_red = true
            @printer.make_header_red
          end

          unless @example_group_red
            @example_group_red = true
            @printer.make_example_group_header_red(example_group_number)
          end

          @printer.move_progress(percent_done)

          exception = example.metadata[:execution_result][:exception]
          exception_details = if exception
            {
              :message => exception.message,
              :backtrace => format_backtrace(exception.backtrace, example).join("\n")
            }
          else
            false
          end
          extra = extra_failure_content(exception)

          @printer.print_example_failed(
            example.execution_result[:pending_fixed],
            example.description,
            example.execution_result[:run_time],
            @failed_examples.size,
            exception_details,
            (extra == "") ? false : extra,
            false
          )
          @printer.flush
        end
      end
    end
  end
end
