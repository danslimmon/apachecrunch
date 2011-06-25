# An element in a log format
#
# Exposes:
#    abbrev: The Apache abbreviation for the element (such as "%h" or "%u" or "%{Referer}i")
#    name: A short name for the element (such as "remote_host", "remote_user", or "reqhead_referer")
#    regex: A regex that should match such an element ("[A-Za-z0-9.-]+", "[^:]+", ".+")
class LogFormatElement
    attr_accessor :abbrev, :name, :regex

    def initialize(abbrev, name, regex)
        @abbrev = abbrev
        @name = name
        @regex = regex
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


# Generates LogFormatElement instances
class LogFormatElementFactory
    @@ABBREV_MAP = {
        "%h" => LogFormatElement.new("%h", "remote_host", "[A-Za-z0-9.-]"),
        "%u" => LogFormatElement.new("%h", "remote_user", "[^:]+")
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
        LogFormatElement.new(abbrev, _reqheader_name_to_element_name(header_name), ".*")
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
    end

    # Appends a given token (a LogFormatElement or LogFormatString) to the tokens list
    def append(token)
        @tokens << token
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
        elsif f_string =~ /^(%\{.*\}[Ceino])(.*)/
            # "Contents of" element (e.g. "%{Accept}i")
            return [@element_factory.from_abbrev($1), $2]
        elsif f_string =~ /^(.+?)(%.*|$)/
            # Bare string up until the next %, or up until the end of the format string
            return [LogFormatString.new($1), $2]
        end
    end
end
