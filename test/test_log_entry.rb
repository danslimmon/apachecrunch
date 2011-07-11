class LogEntry_DerivationSourceElement < LogFormatElement
    @name = :derivation_source

    def self.derive(name, our_own_value)
        if name == :derived
            return "derived from #{our_own_value}"
        end

        nil
    end
end


class TestLogEntry < Test::Unit::TestCase
    def setup
        @inst = LogEntry.new({:derived => LogEntry_DerivationSourceElement})
    end

    def teardown
        @inst = nil
    end

    # Tests direct assignment of an element.
    def test_assign
        @inst[:bar] = "test_value"
        assert_equal(@inst[:bar], "test_value")
    end

    # Tests derivation of one element from another.
    def test_derive
        @inst[:derivation_source] = "source text"
        assert_equal(@inst[:derived], "derived from source text")
    end

    # Tests access to an absent element.
    def test_access_absent
        assert_nil(@inst[:nonexistent])
    end
end
