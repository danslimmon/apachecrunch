require "date"
require "tempfile"

require 'entry'
require 'format'
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


    # Parses a log file given a path and a Format instance
    class LogParser
        # Initializes the parser with the path to a log file and a EntryParser.
        def initialize(path, entry_parser)
            @path = path
            @entry_parser = entry_parser

            @_file = nil
        end

        # Returns the next entry in the log file as a hash, or nil if we've reached EOF.
        #
        # The keys of the hash are names of LogFormatElements (e.g. "remote_host", "reqheader_referer")
        def next_entry
            @_file = open(@path) if @_file.nil?

            while line_text = @_file.gets
                return nil if line_text.nil?
                logline = @entry_parser.from_text(line_text)

                # The LogLineFactory returns nil and writes a warning if the line text doesn't
                # match our expected format.
                next if logline.nil?

                return logline
            end
        end

        # Resets the LogParser's filehandle so we can start over.
        def reset
            @_file = nil
        end

        # Makes the LogParser close its current log file and start parsing a new one instead
        #
        # `new_target` is a writable file object that the parser should start parsing, and if
        # in_place is true, we actually replace the contents of the current target with those
        # of the new target.
        def replace_target(new_target, in_place)
            new_target.close

            if in_place
                old_path = @_file.path
                File.rename(new_target.path, old_path)
            else
                @path = new_target.path
            end

            @_file = nil
        end
    end

    # Makes a LogParser given the parameters we want to work with.
    #
    # This is the class that most external code should instatiate to begin using this library.
    class LogParserFactory
        # Returns a new LogParser instance for the given log file, which should have the given Apache
        # log format.
        def self.log_parser(format_string, path, progress_meter)
            # First we generate a Format instance based on the format string we were given
            log_format = FormatFactory.from_format_string(format_string)

            # Now we generate a line parser
            log_line_parser = EntryParser.new(log_format, progress_meter)

            # And now we can instantiate and return a LogParser
            return LogParser.new(path, log_line_parser)
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
