require 'test/stub'

class TestLogEntry < Test::Unit::TestCase
    def setup
        @inst = LogEntry.new({:derived => StubDerivationSourceElement})
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
