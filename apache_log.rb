require "date"
require "tempfile"

# An element in a log format
#
# Exposes:
#    abbrev: The Apache abbreviation for the element (such as "%h" or "%u" or "%{Referer}i")
#    name: A short name for the element (such as "remote_host", "remote_user", or "reqhead_referer")
#    regex: A regex that should match such an element ("[A-Za-z0-9.-]+", "[^:]+", ".+")
#
# If 'caster' is passed to the constructor, it should be a class with a method called "cast" which
# transforms a string to the appropriate data type or format for consumption.  For example, the
# IntegerCast class transforms "562" to 562.  The correct cast of a string can then be performed
# by passing that string to this LogFormaElement instance's "cast" method.
class LogFormatElement
    attr_accessor :abbrev, :name, :regex

    def initialize(abbrev, name, regex, caster=nil)
        @abbrev = abbrev
        @name = name
        @regex = regex
        @caster = caster
    end

    def cast(string_value)
        if @caster.nil?
            return string_value
        else
            return @caster.cast(string_value)
        end
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


# Converts a string to an integer
class IntegerCast
    def self.cast(string_value)
        string_value.to_i
    end
end


# Converts a CLF-formatted string to an integer
#
# "CLF-formatted" means that if the value is 0, the string will be a single hyphen instead of
# a number.  Like %b, for instance.
class CLFIntegerCast
    def self.cast(string_value)
        if string_value == "-"
            return 0
        end
        string_value.to_i
    end
end


# Generates LogFormatElement instances
class LogFormatElementFactory
    @@ABBREV_MAP = {
        "%h" => LogFormatElement.new("%h", "remote_host", %q![A-Za-z0-9.-]+!),
        "%l" => LogFormatElement.new("%l", "log_name", %q!\S+!),
        "%u" => LogFormatElement.new("%u", "remote_user", %q![^:]+!),
        "%t" => LogFormatElement.new("%t", "time", %q!\[\d\d/[A-Za-z]{3}/\d\d\d\d:\d\d:\d\d:\d\d -?\d\d\d\d\]!),
        "%r" => LogFormatElement.new("%r", "req_firstline", %q![^"]+!),
        "%s" => LogFormatElement.new("%s", "status", %q!\d+|-!),
        "%B" => LogFormatElement.new("%b", "bytes_sent", %q!\d+!, caster=IntegerCast),
        "%b" => LogFormatElement.new("%b", "bytes_sent", %q![\d-]+!, caster=CLFIntegerCast),
        "%D" => LogFormatElement.new("%D", "serve_time_ms", %q!\d+!, caster=IntegerCast)
    }

    # Takes an Apache log format abbreviation and returns a corresponding LogFormatElement
    def from_abbrev(abbrev)
        if @@ABBREV_MAP.key?(abbrev)
            # Standard Apache log format abbreviation
            return @@ABBREV_MAP[abbrev]
        elsif abbrev =~ /^%\{([A-Za-z0-9-]+)\}i/
            # HTTP request header
            return _reqheader_element(abbrev, $1)
        end
    end

    # Returns a LogFormatElement based on an HTTP header
    def _reqheader_element(abbrev, header_name)
        LogFormatElement.new(abbrev, _reqheader_name_to_element_name(header_name), %q![^"]*!)
    end

    # Lowercases header name and turns hyphens into underscores
    def _reqheader_name_to_element_name(header_name)
        "reqheader_" + header_name.downcase().gsub("-", "_")
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
        elsif f_string =~ /^(%\{.+?\}[Ceino])(.*)/
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
    def initialize(log_format)
        @log_format = log_format
        @_elements = log_format.elements
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

        line_hash = {"text" => log_text}
        @_elements.each_with_index do |element, i|
            line_hash[element.name] = element.cast(Regexp.last_match(i + 1))
        end
        line_hash
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

    # Returns a file object whose contents will replace those of the log file when replace() is
    # called
    def begin_replacement
        @_rep_file = Tempfile.new("apache_log_parser")
    end

    # Replaces the file we're parsing with the contents of the replacement file returned by
    # begin_replacement()
    def replace
        path = @_file.path
        @_file = nil
        @_rep_file.close
        File.rename(@_rep_file.path, path)
    end
end

# Makes a LogParser given the parameters we want to work with.
#
# This is the class that most external code should instatiate to begin using this library.
class LogParserFactory
    # Returns a new LogParser instance for the given log file, which should have the given Apache
    # log format.
    def self.log_parser(format_string, path)
        # First we generate a LogFormat instance based on the format string we were given
        format_factory = LogFormatFactory.new
        log_format = format_factory.from_format_string(format_string)

        # Now we generate a line parser
        log_line_parser = LogLineParser.new(log_format)

        # And now we can instantiate and return a LogParser
        return LogParser.new(path, log_line_parser)
    end
end


# Finds a named log format string in the configuration file(s)
class FormatStringFinder
    # Finds the given format string in the configuration file(s)
    #
    # If none exists, returns nil.
    def find(format_name)
        config_file = open("log_formats.rb")
        formats = {}
        eval config_file.read

        return formats[format_name.to_sym].gsub(/\\"/, '"')
    end
end
