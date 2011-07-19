require 'format_token_definition'
require 'derivation'

class ApacheCrunch
    # Abstract for a token in a log format
    class FormatToken
        # Performs whatever initial population is necessary for the token.
        def populate!; raise NotImplementedError; end

        def name; raise NotImplementedError; end
        def regex; raise NotImplementedError; end
        def captured?; raise NotImplementedError; end
        def derivation_rule; raise NotImplementedError; end
    end


    # A predefined token like %q or %r from the Apache log.
    class PredefinedToken < FormatToken
        def populate!(token_definition)
            @token_definition = token_definition
        end

        def name; @token_definition.name; end
        def regex; @token_definition.regex; end
        def captured?; @token_definition.captured; end
        def derivation_rule; @token_definition.derivation_rule; end
    end


    # A bare string in a log format.
    class StringToken < FormatToken
        # Initializes the instance given the string it represents
        def populate!(string_value)
            @_string_value = string_value
        end

        def name; nil; end

        def regex
            # Make sure there aren't any regex special characters in the string that will confuse
            # the parsing later.
            Regexp.escape(@_string_value)
        end

        def captured?; false; end
        def derivation_rule; NullDerivationRule.new; end
    end


    # A token based on a request header.
    class ReqheaderToken < FormatToken
        def populate!(header_name)
            @_name = _header_name_to_token_name(header_name)
        end

        def name; @_name; end
        def regex; '[^"]*'; end
        def captured?; true; end
        def derivation_rule; NullDerivationRule.new; end

        # Lowercases header name and turns hyphens into underscores
        def _header_name_to_token_name(header_name)
            ("reqheader_" + header_name.downcase().gsub("-", "_")).to_sym
        end
    end


    # A token based on an arbitrary regular expression.
    class RegexToken < FormatToken
        def populate!(regex_name, regex_text)
            @_name = "regex_#{regex_name}".to_sym
            @_regex = regex_text
        end

        def name; @_name; end
        def regex; @_regex; end
        def captured?; true; end
        def derivation_rule; NullDerivationRule.new; end
    end


    # Generates FormatToken instances.
    #
    # This class does the work of figuring out which FormatToken subclass to make.
    class FormatTokenFactory
        # Takes an Apache log format abbreviation and returns a corresponding FormatToken
        def self.from_abbrev(abbrev)
            tok = nil

            token_def = TokenDictionary.fetch(abbrev)
            if token_def
                # We found it in the dictionary, so just return a Token based on it
                tok = PredefinedToken.new
                tok.populate!(token_def)
            elsif abbrev !~ /^%/
                tok = StringToken.new
                tok.populate!(abbrev)
            elsif abbrev == "%%"
                tok = StringToken.new
                tok.populate!("%")
            elsif abbrev =~ /^%\{([A-Za-z0-9-]+)\}i/
                # HTTP request header
                tok = ReqheaderToken.new
                tok.populate!($1)
            elsif abbrev =~ /^%\{(.*?):([^}]+)\}r/
                # Arbitrary regex
                tok = RegexToken.new
                tok.populate!($1, $2)
            end

            tok
        end
    end
end
