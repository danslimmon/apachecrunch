class StubAlphanumericFormatToken < ApacheCrunch::FormatToken
    def name; :alnum; end
    def regex; %q![A-Za-z0-9]+!; end
    def captured?; true; end
    def derivation_rule; ApacheCrunch::NullDerivationRule.new; end
end

class StubNumericFormatToken < ApacheCrunch::FormatToken
    def name; :num; end
    def regex; %q!\d+!; end
    def captured?; true; end
    def derivation_rule; ApacheCrunch::NullDerivationRule.new; end
end

class StubStringFormatToken < ApacheCrunch::FormatToken
    def initialize(s); @_s = s; end
    def regex; @_s; end
    def captured?; false; end
    def derivation_rule; ApacheCrunch::NullDerivationRule.new; end
end

class StubDerivedToken < ApacheCrunch::FormatToken
    @name = :derived
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
    def captured?; true; end
end

class StubFormatTokenFactory
    def from_abbrev(abbrev)
        return StubFormatToken.new
    end

    def from_string(s)
        return StubStringToken.new(s)
    end
end

class StubFormat
    attr_accessor :tokens
end

class StubEntry
    attr_accessor :captured_elements
    def initialize; @captured_elements = []; end
end

class StubElement
    attr_accessor :token, :value, :name, :derivation_rule
    def populate!(token, value)
        @token = token
        @value = value
        @name = token.name
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

class StubEntryParser
    def parse_return_values=(value_list)
        @_parse_return_values = value_list.clone
    end
    def parse(format, log_text); @_parse_return_values.shift; end
end
