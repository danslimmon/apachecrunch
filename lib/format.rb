class ApacheCrunch
    # Represents a particular Apache log format
    class Format
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
        #
        # Each group matched will correspond to an element in the log format.
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

    # Parses a log format string
    class FormatParser
        # Initializes the FormatParser
        #
        # Takes a FormatElementFactory instance, and you can inject a replacement for the
        # LogFormatString class.
        def initialize(format_element_factory, format_string_cls=LogFormatString)
            @_element_factory = format_element_factory
            @_format_string_cls = format_string_cls
        end

        # Parses the given format_string (e.g. "%h %u %s #{Referer}i") and returns a list of tokens.
        #
        # These tokens are all instances of LogFormatString or LogFormatElement.
        def parse_string(format_string)
            s = format_string
            tokens = []
            
            until s.empty?
                token, s = _shift_token(s)
                tokens << token
            end

            tokens
        end

        # Finds the first token (a LogFormatElement or LogFormatString) in a format string
        #
        # Returns a list containing the token and the new format string (with the characters that
        # correspond to the token removed)
        def _shift_token(f_string)
            if f_string =~ /^%%(.*)/
                # Literal "%"
                return [@_format_string_cls.new("%%"), $1]
            elsif f_string =~ /^(%[A-Za-z])(.*)/
                # Simple element (e.g. "%h", "%u")
                return [@_element_factory.from_abbrev($1), $2]
            elsif f_string =~ /^%[<>]([A-Za-z])(.*)/
                # No idea how to handle mod_log_config's "which request" system yet, so we
                # ignore it.
                return [@_element_factory.from_abbrev("%" + $1), $2]
            elsif f_string =~ /^(%\{.+?\}[Ceinor])(.*)/
                # "Contents of" element (e.g. "%{Accept}i")
                return [@_element_factory.from_abbrev($1), $2]
            elsif f_string =~ /^(.+?)(%.*|$)/
                # Bare string up until the next %, or up until the end of the format string
                return [@_format_string_cls.new($1), $2]
            end
        end
    end


    # Turns a string specifying an Apache log format into a Format instance
    class FormatFactory
        # Constructs and returns a Format instance based on the given Apache log format string
        def self.from_format_string(f_string)
            logformat = Format.new
            logformat.format_string = f_string

            element_factory = LogFormatElementFactory.new

            format_parser = FormatParser.new(element_factory)
            logformat.tokens = format_parser.parse_string(f_string)

            logformat
        end
    end
end
