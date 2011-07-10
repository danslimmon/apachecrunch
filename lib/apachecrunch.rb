require "date"
require "tempfile"

require 'log_element'


# A parsed entry from the log.
#
# Acts like a hash, in that you get at the log elements (e.g. "url_path", "remote_host") by
# as entry[name].
class LogEntry
    def initialize(derivation_map)
        @_derivation_map = derivation_map
        @_attributes = {}
    end

    def []=(name, value)
        @_attributes[name] = value
    end

    def [](name)
        return @_attributes[name] if @_attributes.key?(name)

        derived_from_cls = @_derivation_map[name]
        return nil if derived_from_cls.nil?

        derived_from_cls.derive(name, @_attributes[derived_from_cls.name])
    end

    def merge!(hsh)
        @_attributes.merge!(hsh)
    end
end


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


# Represents a particular Apache log format
class LogFormat
    attr_accessor :format_string, :tokens

    def initialize
        @tokens = []
        @_regex = nil
    end

    # Appends a given token (a LogFormatElement or LogFormatString) to the tokens list
    def append(token)
        @tokens << token
    end

    # Returns a compiled regex to match a log line in this format
    def regex
        return @_regex unless @_regex.nil?

        r = "^"
        @tokens.each do |tok|
            # We only care to remember the LogFormatElements.  No need to put parentheses
            # around LogFormatString shit.
            if tok.respond_to?(:name)
                r += "(" + tok.regex + ")"
            else
                r += tok.regex
            end
        end
        r += "$"

        @_regex = Regexp.compile(r)
        @_regex
    end

    # Returns the list of LogFormatElements, in order, of the interpolated things in the format.
    #
    # For example, if the log format string were "%h %u %{Referer}i", this would return the
    # LogFormatElement instances for "%h", "%u", and "%{Referer}i".
    def elements
        @tokens.find_all do |tok|
            tok.respond_to?(:name)
        end
    end

    # Returns hash mapping names of elements to the element class from which they can be derived.
    def derivation_map
        hsh = {}
        elements.each do |tok|
            tok.derived_elements.each do |derived_element|
                hsh[derived_element.name] = tok.class
            end
        end

        hsh
    end
end


# Turns a string specifying an Apache log format into a LogFormat instance
class LogFormatFactory
    def initialize
        @element_factory = LogFormatElementFactory.new
    end

    # Constructs and returns a LogFormat instance based on the given Apache log format string
    def from_format_string(f_string)
        logformat = LogFormat.new
        logformat.format_string = f_string

        until f_string.empty?
            token, f_string = _shift_token(f_string)
            logformat.append(token)
        end

        logformat
    end

    # Finds the first token (a LogFormatElement or LogFormatString) in a format string
    #
    # Returns a list containing the token and the new format string (with the characters that
    # correspond to the token removed)
    def _shift_token(f_string)
        if f_string =~ /^%%(.*)/
            # Literal "%"
            return [LogFormatString.new("%%"), $1]
        elsif f_string =~ /^(%[A-Za-z])(.*)/
            # Simple element (e.g. "%h", "%u")
            return [@element_factory.from_abbrev($1), $2]
        elsif f_string =~ /^%[<>]([A-Za-z])(.*)/
            # No idea how to handle mod_log_config's "which request" system yet, so we
            # ignore it.
            return [@element_factory.from_abbrev("%" + $1), $2]
        elsif f_string =~ /^(%\{.+?\}[Ceinor])(.*)/
            # "Contents of" element (e.g. "%{Accept}i")
            return [@element_factory.from_abbrev($1), $2]
        elsif f_string =~ /^(.+?)(%.*|$)/
            # Bare string up until the next %, or up until the end of the format string
            return [LogFormatString.new($1), $2]
        end
    end
end


# Makes log line hashes based on log file text
class LogLineParser
    # Initializes the instance given a LogFormat instance
    def initialize(log_format, progress_meter)
        @log_format = log_format
        @progress_meter = progress_meter

        @_elements = log_format.elements
        @_derivation_map = log_format.derivation_map
    end

    # Returns a log line hash built from a line of text, or nil if the line was malformatted
    #
    # The keys of the hash are names of LogFormatElements (e.g. "remote_host", "reqheader_referer")
    def from_text(log_text)
        match = (log_text =~ @log_format.regex)
        if match.nil?
            warn "Log line did not match expected format: #{log_text}"
            return nil
        end
        
        # Make a hash mapping all parsed elements to their values in the entry
        match_groups = Regexp.last_match.to_a
        match_groups.shift # First value is the whole matched string, which we do not want
        element_values = Hash[*@_elements.zip(match_groups).flatten]

        # Start building the return value
        entry = LogEntry.new(@_derivation_map)
        entry[:text] = log_text
        # Insert all the elements specified in the LogFormat
        entry.merge!(_elements_to_hash(element_values))

        @progress_meter.output_progress(entry)
        entry
    end

    # Returns a hash of "element name" => value pairs based on a hash of element => value pairs.
    def _elements_to_hash(element_values)
        hsh = {}
        element_values.each_pair do |element, value|
            hsh[element.name] = value
        end

        hsh
    end

    # Returns hash of derived "element name" => value pairs from a hash of element => value pairs.
    #
    # That is, we go through the elements passed and if any offers derived elements, we include
    # those in the return value.
    def _derived_elements(element_values)
        hsh = {}
        element_values.each_pair do |element, value|
            hsh.merge!(element.derived_values(value))
        end

        hsh
    end
end


# Parses a log file given a path and a LogFormat instance
class LogParser
    # Initializes the parser with the path to a log file and a LogLineParser.
    def initialize(path, ll_parser)
        @path = path
        @ll_parser = ll_parser

        @_file = nil
    end

    # Returns the next entry in the log file as a hash, or nil if we've reached EOF.
    #
    # The keys of the hash are names of LogFormatElements (e.g. "remote_host", "reqheader_referer")
    def next_entry
        @_file = open(@path) if @_file.nil?

        while line_text = @_file.gets
            return nil if line_text.nil?
            logline = @ll_parser.from_text(line_text)

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
        # First we generate a LogFormat instance based on the format string we were given
        format_factory = LogFormatFactory.new
        log_format = format_factory.from_format_string(format_string)

        # Now we generate a line parser
        log_line_parser = LogLineParser.new(log_format, progress_meter)

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
