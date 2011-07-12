class StubFormatElement < LogFormatElement
    @abbrev = "%z"
    @name = :stub
    @regex = %q!.*!
end

class StubAlphanumericFormatElement < LogFormatElement
    @abbrev = "%Z"
    @name = :alnum
    @regex = %q![A-Za-z0-9]+!
end

class StubNumericFormatElement < LogFormatElement
    @abbrev = "%y"
    @name = :num
    @regex = %q!\d+!
end

class StubFormatString
    attr_accessor :regex
    def initialize(regex)
        @regex = regex
    end
end

class StubDerivedElement < LogFormatElement
    @abbrev = ""
    @name = :derived
    @regex = %q!.*!
end

class StubDerivationSourceElement < LogFormatElement
    @name = :derivation_source

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
        if abbrev =~ /^%/
            return StubFormatElement.new
        else
            return StubFormatString.new
        end
    end
end
