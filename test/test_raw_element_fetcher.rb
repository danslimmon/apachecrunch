require 'test/stub'

class TestFormat < Test::Unit::TestCase
    def setup
        @inst = ApacheCrunch::RawElementFetcher.new
    end

    def teardown
        @inst = nil
    end

    # Tests a successful fetch call
    def test_fetch
        entry = StubEntry.new
        entry.captured_elements = [StubElement.new(StubAlphanumericFormatToken.new, "foo123"),
                                   StubElement.new(StubNumericFormatToken.new, 54321)]
        assert_equal("foo123", @inst.fetch(entry, StubAlphanumericFormatToken.new.name).value)
        assert_equal(54321, @inst.fetch(entry, StubNumericFormatToken.new.name).value)
    end

    # Tests a fetch call for an element that's not there
    def test_fetch_missing
        entry = StubEntry.new
        entry.captured_elements = [StubElement.new(StubAlphanumericFormatToken.new, "foo123"),
                                   StubElement.new(StubNumericFormatToken.new, 54321)]
        assert_nil(@inst.fetch(entry, :missing_element))
    end
end
