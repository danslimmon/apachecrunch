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
        alnum_element = StubElement.new
        alnum_element.populate!(StubAlphanumericFormatToken.new, "foo123")
        ds_element = StubElement.new
        ds_element.populate!(StubDerivationSourceToken.new, "herpaderp")

        @inst.dep_inject!(StubDerivationRuleFinder.new(StubDerivationRule.new))
        entry.captured_elements = {:alnum => alnum_element, :derivation_source => ds_element}
        assert_equal("derived from herpaderp", @inst.fetch(entry, :derived))
    end

    # Tests a fetch call for an element that's not derivable
    def test_fetch_missing
        entry = StubEntry.new
        alnum_element = StubElement.new
        alnum_element.populate!(StubAlphanumericFormatToken.new, "foo123")
        ds_element = StubElement.new
        ds_element.populate!(StubDerivationSourceToken.new, "herpaderp")

        entry.captured_elements = [alnum_element, ds_element]
        assert_nil(@inst.fetch(entry, :missing_element))
    end
end
