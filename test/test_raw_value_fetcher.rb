require 'test/stub'

class TestRawValueFetcher < Test::Unit::TestCase
    def setup
        @inst = ApacheCrunch::RawValueFetcher.new
    end

    def teardown
        @inst = nil
    end

    # Tests a successful fetch call
    def test_fetch
        entry = StubEntry.new
        alnum_element = StubElement.new
        alnum_element.populate!(StubAlphanumericFormatToken.new, "foo123")
        num_element = StubElement.new
        num_element.populate!(StubNumericFormatToken.new, 54321)

        entry.captured_elements = {:alnum => alnum_element, :num => num_element}
        assert_equal("foo123", @inst.fetch(entry, StubAlphanumericFormatToken.new.name))
        assert_equal(54321, @inst.fetch(entry, StubNumericFormatToken.new.name))
    end

    # Tests a fetch call for an element that's not there
    def test_fetch_missing
        entry = StubEntry.new
        alnum_element = StubElement.new
        alnum_element.populate!(StubAlphanumericFormatToken.new, "foo123")
        num_element = StubElement.new
        num_element.populate!(StubNumericFormatToken.new, 54321)

        entry.captured_elements = [alnum_element, num_element]
        assert_nil(@inst.fetch(entry, :missing_element))
    end
end
