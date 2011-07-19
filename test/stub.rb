class StubAlphanumericFormatToken < ApacheCrunch::FormatToken
    def name; :alnum; end
    def regex; %q![A-Za-z0-9]+!; end
    def derivation_rule; nil; end
end

class StubNumericFormatToken < ApacheCrunch::FormatToken
    def name; :num; end
    def regex; %q!\d+!; end
    def derivation_rule; nil; end
end

class StubStringToken < ApacheCrunch::FormatToken
    @captured = false

    def initialize(s)
        @regex = s
    end
end

class StubDerivedToken < ApacheCrunch::FormatToken
    @abbrev = ""
    @name = :derived
    @regex = %q!.*!
end

class StubDerivationRule
end

class StubDerivationSourceToken
    def derivation_rule; StubDerivationRule.new; end
end

class StubFormatTokenFactory
    def from_abbrev(abbrev)
        return StubFormatToken.new
    end

    def from_string(s)
        return StubStringToken.new(s)
    end
end

class StubEntry
    attr_accessor :captured_elements
end

class StubElement
    attr_accessor :token, :value, :name
    def initialize(token, value)
        @token = token
        @value = value
        @name = @token.name
    end
end
