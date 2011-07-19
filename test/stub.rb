class StubAlphanumericFormatToken < ApacheCrunch::FormatToken
    def name; :alnum; end
    def regex; %q![A-Za-z0-9]+!; end
    def derivation_rule; ApacheCrunch::NullDerivationRule.new; end
end

class StubNumericFormatToken < ApacheCrunch::FormatToken
    def name; :num; end
    def regex; %q!\d+!; end
    def derivation_rule; ApacheCrunch::NullDerivationRule.new; end
end

class StubStringToken < ApacheCrunch::FormatToken
    @captured = false

    def initialize(s)
        @regex = s
    end
    def derivation_rule; ApacheCrunch::NullDerivationRule.new; end
end

class StubDerivedToken < ApacheCrunch::FormatToken
    @abbrev = ""
    @name = :derived
    @regex = %q!.*!
    def derivation_rule; ApacheCrunch::NullDerivationRule.new; end
end

class StubDerivationRule
    def derived_elements; [:derived]; end
    def derive_all(value)
        {:derived => "derived from #{value}"}
    end
end

class StubDerivationSourceToken
    def derivation_rule; StubDerivationRule.new; end
    def name; :derivation_source; end
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
    attr_accessor :token, :value, :name, :derivation_rule
    def initialize(token, value)
        @token = token
        @value = value
        @name = @token.name
        @derivation_rule = @token.derivation_rule
    end
end

class StubValueFetcher
    def initialize(fetch_result); @fetch = fetch_result; end
    def fetch(*args); @fetch; end
end

# Pretends to be a Raw- or DerivedValueFetcher class, but StubValueFetcher instance returned by
# new() just fetches whatever you set fetch_result to.
class StubValueFetcherClass
    attr_accessor :fetch_result
    def new(*args)
        StubValueFetcher.new(@fetch_result)
    end
end
