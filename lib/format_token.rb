require 'format_token_definition'

class ApacheCrunch
    # Abstract for a token in a log format
    class FormatToken
        attr_accessor :token_definition

        # Performs whatever initial population is necessary for the token.
        def populate!; raise NotImplementedError; end

        def name; raise NotImplementedError; end
        def regex; raise NotImplementedError; end
        def captured?; raise NotImplementedError; end
    end


    # A predefined token like %q or %r from the Apache log.
    class PredefinedToken
        def populate!(token_definition)
            @token_definition = token_definition
        end

        def name; @token_definition.name; end
        def regex; @token_definition.regex; end
        def captured?; @token_definition.captured; end
    end


    # A bare string in a log format.
    class StringToken < FormatToken
        # Initializes the instance given the string it represents
        def populate!(string_value)
            @_string_value = string_value
        end

        def name; nil; end

        def regex
            r = @_string_value
            # Make sure there aren't any regex special characters in the string that will confuse
            # the parsing later.
            '()[].?+{}\\'.each_char do |special_char|
                while r.include?(special_char) do
                    r = r.gsub(special_char, '\\' + special_char)
                end
            end

            r
        end

        def captured?; false; end
    end


    class ReqheaderToken < FormatToken
        @name = nil
        @abbrev = nil
        @regex = %q![^"]*!
        @caster = nil
        @derivation_rule = nil
        @captured = true
    end


    class RegexToken < FormatToken
        @name = nil
        @abbrev = nil
        @regex = nil
        @caster = nil
        @derivation_rule = nil
        @captured = true
    end


    # Generates FormatToken instances.
    #
    # This class does the work of figuring out which FormatToken subclass to make.
    class FormatTokenFactory
        # Takes an Apache log format abbreviation and returns a corresponding FormatToken
        def self.from_abbrev(abbrev)
            token = TokenDictionary.fetch_by_abbrev(abbrev)
            if token
                # We found it in the dictionary, so just return a Token based on it
                return token
            elsif abbrev =~ /^%\{([A-Za-z0-9-]+)\}i/
                # HTTP request header
                return _reqheader_token(abbrev, $1)
            elsif abbrev =~ /^%\{(.*?):([^}]+)\}r/
                # Arbitrary regex
                return _regex_token(abbrev, $1, $2)
            end

            raise "Unknown format token '#{abbrev}'"
        end

        # Returns a FormatToken subclass instance based on a static string.
        #
        # This element not be captured by the EntryParser since it's always the same.
        def from_string(s)
            StringToken.new(s)
        end

        # Returns a format element based on an HTTP header
        def _reqheader_element(abbrev, header_name)
            element = ReqheaderToken.new

            element.name = _header_name_to_element_name(header_name)
            element.abbrev = abbrev
            element.regex = %q![^"]*!

            element
        end

        # Returns a format element based on an arbitrary regex
        def _regex_element(abbrev, regex_name, regex)
            element = RegexToken.new

            element.abbrev = abbrev
            element.regex = regex
            element.name = "regex_#{regex_name}".to_sym

            element
        end

        # Lowercases header name and turns hyphens into underscores
        def _header_name_to_element_name(header_name)
            ("reqheader_" + header_name.downcase().gsub("-", "_")).to_sym
        end
    end

    class ReqheaderTokenBuilder
        def initialize(reqheader_token_cls=ReqheaderToken)
            @_ReqheaderToken = reqheader_token_cls
        end

        def build(header_name, abbrev)
            token_name = ("reqheader_" + header_name.downcase().gsub("-", "_")).to_sym
        end
    end
end
