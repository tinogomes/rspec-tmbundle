require 'cgi'
require 'rspec/core/formatters/html_formatter'

# This formatter is only used for RSpec 3 (older RSpec versions ship their own TextMateFormatter).
module RSpec
  module Mate
    module Formatters
      class BacktraceFormatter < RSpec::Core::BacktraceFormatter
        def backtrace_line(line)
          original = super
          return nil unless original
          CGI.escapeHTML(original).sub(/([^:]*\.e?rb):(\d*)/) do
            "<a href=\"txmt://open?url=file://#{File.expand_path($1)}&line=#{$2}\">#{$1}:#{$2}</a> "
          end
        end
      end

      class HtmlPrinterWithUnescapedBacktrace < RSpec::Core::Formatters::HtmlPrinter
        def print_example_failed(pending_fixed, description, run_time, failure_id, exception, extra_content, escape_backtrace = false)
          # Call implementation from superclass, but ignore `escape_backtrace` and always pass `false` instead. 
          super(pending_fixed, description, run_time, failure_id, exception, extra_content, false)
        end
      end

      class TextMateFormatter < RSpec::Core::Formatters::HtmlFormatter
        RSpec::Core::Formatters.register self, *RSpec::Core::Formatters::Loader.formatters[superclass]

        def initialize(output)
          super
          @printer = HtmlPrinterWithUnescapedBacktrace.new(output)
        end

        def backtrace_formatter
          @backtrace_formatter ||= RSpec::Mate::Formatters::BacktraceFormatter.new
        end

        def format_backtrace(backtrace, example)
          backtrace_formatter.format_backtrace(backtrace, example.metadata)
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
