class StubFormatToken < ApacheCrunch::FormatToken
    @abbrev = "%z"
    @name = :stub
    @regex = %q!.*!
    @captured = true
end

class StubAlphanumericFormatToken < ApacheCrunch::FormatToken
    @abbrev = "%Z"
    @name = :alnum
    @regex = %q![A-Za-z0-9]+!
    @captured = true
end

class StubNumericFormatToken < ApacheCrunch::FormatToken
    @abbrev = "%y"
    @name = :num
    @regex = %q!\d+!
    @captured = true
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

class StubDerivationSourceToken < ApacheCrunch::FormatToken
    @name = :derivation_source
    @captured = true

    def derived_elements
        [StubDerivedToken]
    end

    def self.derive(name, our_own_value)
        if name == :derived
            return "derived from #{our_own_value}"
        end

        nil
    end
end

class StubFormatTokenFactory
    def from_abbrev(abbrev)
        return StubFormatToken.new
    end

    def from_string(s)
        return StubStringToken.new(s)
    end
end
