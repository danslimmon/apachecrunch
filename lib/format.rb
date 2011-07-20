require 'format_token'

class ApacheCrunch
    # Represents a particular Apache log format
    class Format
        attr_accessor :tokens

        def initialize
            @tokens = []
        end

        def captured_tokens
            @tokens.find_all do |tok|
                tok.captured?
            end
        end
    end

    # Parses a log format definition
    class FormatParser
        # Initializes the FormatParser
        #
        # Takes a FormatElementFactory instance.
        def initialize
            @_FormatTokenFactory = FormatTokenFactory
        end

        # Handles dependency injection
        def dep_inject!(format_token_factory_cls)
            @_FormatTokenFactory = format_token_factory_cls
        end

        # Parses the given format_def (e.g. "%h %u %s #{Referer}i") and returns a list of tokens.
        #
        # These tokens are all instances of a LogFormatElement subclass.
        def parse_def(format_def)
            s = format_def
            tokens = []
            
            until s.empty?
                token, s = _shift_token(s)
                tokens << token
            end

            tokens
        end

        # Finds the first token in a format definition
        #
        # Returns a list containing the token and the new format definition (with the characters
        # that correspond to the token removed)
        def _shift_token(format_def)
            if format_def =~ /^%%(.*)/
                # Literal "%"
                return [@_FormatTokenFactory.from_abbrev("%%"), $1]
            elsif format_def =~ /^(%[A-Za-z])(.*)/
                # Simple element (e.g. "%h", "%u")
                return [@_FormatTokenFactory.from_abbrev($1), $2]
            elsif format_def =~ /^%[<>]([A-Za-z])(.*)/
                # No idea how to handle mod_log_config's "which request" system yet, so we
                # ignore it.
                return [@_FormatTokenFactory.from_abbrev("%" + $1), $2]
            elsif format_def =~ /^(%\{.+?\}[Ceinor])(.*)/
                # "Contents of" element (e.g. "%{Accept}i")
                return [@_FormatTokenFactory.from_abbrev($1), $2]
            elsif format_def =~ /^(.+?)(%.*|$)/
                # Bare string up until the next %, or up until the end of the format definition
                return [@_FormatTokenFactory.from_abbrev($1), $2]
            end
        end
    end


    # Turns a string specifying an Apache log format into a Format instance
    class FormatFactory
        # Constructs and returns a Format instance based on the given Apache log format string
        def self.from_format_def(format_def)
            logformat = Format.new

            format_parser = FormatParser.new
            logformat.tokens = format_parser.parse_def(format_def)

            logformat
        end
    end
end
