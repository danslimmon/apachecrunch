require "date"
require "tempfile"

require 'entry'
require 'format'
require 'log_parser'
require 'log_element'

class ApacheCrunch
    # A bare string in a log format
    #
    # Exposes 'regex' for consistency with LogFormatElement, but there shouldn't be anything other
    # than one-to-one character matching in there.
    class LogFormatString
        attr_accessor :regex

        def initialize(regex)
            @regex = regex
        end
    end


    # Finds a named log format string in the configuration file(s)
    class FormatStringFinder
        @@FILE_NAME = "log_formats.rb"
        @@DEFAULT_FORMATS = {
            :ncsa => %q!%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-agent}i\"!,
            :ubuntu => %q!%h %l %u %t \"%r\" %>s %O \"%{Referer}i\" \"%{User-Agent}i\"!
        }

        # Finds the given format string in the configuration file(s)
        #
        # If none exists, returns nil.
        def find(format_name)
            name_as_symbol = format_name.to_sym

            formats = @@DEFAULT_FORMATS.clone
            _search_path.each do |dir|
                config_path = File.join(dir, @@FILE_NAME)
                if File.readable?(config_path)
                    config_file = open(File.join(dir, @@FILE_NAME))
                    eval config_file.read
                end

                if formats.key?(format_name.to_sym)
                    return formats[format_name.to_sym].gsub(/\\"/, '"')
                end
            end

            raise "Failed to find the format '#{format_name}' in the search path: #{_search_path.inspect}"
        end

        def _search_path
            [".", "./etc",
             File.join(ENV["HOME"], ".apachecrunch"),
             "/etc/apachecrunch"]
        end
    end
end
