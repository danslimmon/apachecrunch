require 'test/stub'

class TestDerivedValueFetcher < Test::Unit::TestCase
    def setup
        @inst = ApacheCrunch::DerivedValueFetcher.new
    end

    def teardown
        @inst = nil
    end

    # Tests a successful fetch call
    def test_fetch
        entry = StubEntry.new
        entry.captured_elements = [StubElement.new(StubAlphanumericFormatToken.new, "foo123"),
                                   StubElement.new(StubDerivationSourceToken.new, "herpaderp")]
        assert_equal("derived from herpaderp", @inst.fetch(entry, :derived))
    end

    # Tests a fetch call for an element that's not derivable
    def test_fetch_missing
        entry = StubEntry.new
        entry.captured_elements = [StubElement.new(StubAlphanumericFormatToken.new, "foo123"),
                                   StubElement.new(StubDerivationSourceToken.new, "herpaderp")]
        assert_nil(@inst.fetch(entry, :missing_element))
    end
end
