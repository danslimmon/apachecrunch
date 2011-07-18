require 'cast'

class ApacheCrunch
    # Defines the properties of a known Apache log format token (like %q or %h)
    class FormatTokenDefinition
        class << self; attr_accessor :name, :abbrev, :regex, :caster, :derivation_rule, :captured; end
    end


    class RemoteHostTokenDefinition < FormatTokenDefinition
        @name = :remote_host
        @abbrev = "%h"
        @regex = %q![A-Za-z0-9.-]+!
        @caster = nil
        @derivation_rule = nil
        @captured = true
    end


    class LogNameTokenDefinition < FormatTokenDefinition
        @name = :log_name
        @abbrev = "%l"
        @regex = %q!\S+!
        @caster = nil
        @derivation_rule = nil
        @captured = true
    end


    class RemoteUserTokenDefinition < FormatTokenDefinition
        @name = :remote_user
        @abbrev = "%u"
        @regex = %q![^:]+!
        @caster = nil
        @derivation_rule = nil
        @captured = true
    end


    class TimeTokenDefinition < FormatTokenDefinition
        @name = :time
        @abbrev = "%t"
        @regex = %q!\[\d\d/[A-Za-z]{3}/\d\d\d\d:\d\d:\d\d:\d\d [-+]\d\d\d\d\]!
        @caster = nil
        @derivation_rule = TimeDerivationRule.new
        @captured = true
    end


    class ReqFirstlineTokenDefinition < FormatTokenDefinition
        @name = :req_firstline
        @abbrev = "%r"
        @regex = %q![^"]+!
        @caster = nil
        @derivation_rule = ReqFirstlineDerivationRule.new
        @captured = true
    end


    class StatusTokenDefinition < FormatTokenDefinition
        @name = :status
        @abbrev = "%s"
        @regex = %q!\d+|-!
        @caster = nil
        @derivation_rule = nil
        @captured = true
    end


    class BytesSentTokenDefinition < FormatTokenDefinition
        @name = :bytes_sent
        @abbrev = "%b"
        @regex = %q!\d+!
        @caster = IntegerCast.new
        @derivation_rule = nil
        @captured = true
    end


    class BytesSentTokenDefinition < FormatTokenDefinition
        @name = :bytes_sent
        @abbrev = "%b"
        @regex = %q![\d-]+!
        @caster = CLFIntegerCast.new
        @derivation_rule = nil
        @captured = true
    end


    class BytesSentWithHeadersTokenDefinition < FormatTokenDefinition
        @name = :bytes_sent_with_headers
        @abbrev = "%O"
        @regex = %q!\d+!
        @caster = IntegerCast.new
        @derivation_rule = nil
        @captured = true
    end


    class ServeTimeMicroTokenDefinition < FormatTokenDefinition
        @name = :serve_time_micro
        @abbrev = "%D"
        @regex = %q!\d+!
        @caster = IntegerCast.new
        @derivation_rule = nil
        @captured = true
    end


    class UrlPathTokenDefinition < FormatTokenDefinition
        @name = :url_path
        @abbrev = "%U"
        @regex = %q!/[^?]*!
        @caster = nil
        @derivation_rule = nil
        @captured = true
    end


    class QueryStringTokenDefinition < FormatTokenDefinition
        @name = :query_string
        @abbrev = "%q"
        @regex = %q!\??\S*!
        @caster = nil
        @derivation_rule = nil
        @captured = true
    end


    class ReqMethodTokenDefinition < FormatTokenDefinition
        @name = :req_method
        @abbrev = "%m"
        @regex = %q![A-Z]+!
        @caster = nil
        @derivation_rule = nil
        @captured = true
    end


    class ProtocolTokenDefinition < FormatTokenDefinition
        @name = :protocol
        @abbrev = "%H"
        @regex = %q!\S+!
        @caster = nil
        @derivation_rule = nil
        @captured = true
    end


    # Finds log format elements given information about them.
    class ElementDictionary
        @@_defs = [
                RemoteHostTokenDefinition,
                LogNameTokenDefinition,
                RemoteUserTokenDefinition,
                TimeTokenDefinition,
                ReqFirstlineTokenDefinition,
                StatusTokenDefinition,
                BytesSentTokenDefinition,
                BytesSentTokenDefinition,
                BytesSentWithHeadersTokenDefinition,
                ServeTimeMicroTokenDefinition,
                UrlPathTokenDefinition,
                QueryStringTokenDefinition,
                ReqMethodTokenDefinition,
                ProtocolTokenDefinition
        ]

        # Returns the FormatToken subclass with the given abbreviation.
        #
        # If none exists, returns nil.
        def self.fetch(abbrev)
            @@_defs.each do |token_def|
                if token_def.abbrev == abbrev
                    return token_def
                end
            end

            nil
        end
    end
end
