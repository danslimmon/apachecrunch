class StubFormatElement < LogFormatElement
    @abbrev = "%z"
    @name = :stub
    @regex = %q!.*!
    @captured = true
end

class StubAlphanumericFormatElement < LogFormatElement
    @abbrev = "%Z"
    @name = :alnum
    @regex = %q![A-Za-z0-9]+!
    @captured = true
end

class StubNumericFormatElement < LogFormatElement
    @abbrev = "%y"
    @name = :num
    @regex = %q!\d+!
    @captured = true
end

class StubStringElement < LogFormatElement
    @captured = false

    def initialize(s)
        @regex = s
    end
end

class StubDerivedElement < LogFormatElement
    @abbrev = ""
    @name = :derived
    @regex = %q!.*!
end

class StubDerivationSourceElement < LogFormatElement
    @name = :derivation_source
    @captured = true

    def derived_elements
        [StubDerivedElement]
    end

    def self.derive(name, our_own_value)
        if name == :derived
            return "derived from #{our_own_value}"
        end

        nil
    end
end

class StubLogFormatElementFactory
    def from_abbrev(abbrev)
        return StubFormatElement.new
    end

    def from_string(s)
        return StubStringElement.new(s)
    end
end
