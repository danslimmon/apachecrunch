require 'test/stub'

class TestElementValueFetcher < Test::Unit::TestCase
    def setup
        @inst = ApacheCrunch::ElementValueFetcher.new
        @_raw_fetcher = StubValueFetcherClass.new
        @_derived_fetcher = StubValueFetcherClass.new
    end

    def teardown
        @inst = nil
        @_raw_fetcher = nil
        @_derived_fetcher = nil
    end

    # Tests a successful fetch call that hits a raw element
    def test_fetch_raw
        @_raw_fetcher.fetch_result = "raw value"
        @_derived_fetcher.fetch_result = nil
        @inst.dep_inject!(@_raw_fetcher, @_derived_fetcher)

        entry = StubEntry.new
        assert_equal("raw value", @inst.fetch(entry, :irrelevant))
    end

    # Tests a successful fetch call that hits a derived element
    def test_fetch_derived
        @_raw_fetcher.fetch_result = nil
        @_derived_fetcher.fetch_result = "derived value"
        @inst.dep_inject!(@_raw_fetcher, @_derived_fetcher)

        entry = StubEntry.new
        assert_equal("derived value", @inst.fetch(entry, :irrelevant))
    end

    # Tests a fetch call for an element that's not there
    def test_fetch_missing
        @_raw_fetcher.fetch_result = nil
        @_derived_fetcher.fetch_result = nil
        @inst.dep_inject!(@_raw_fetcher, @_derived_fetcher)

        entry = StubEntry.new
        assert_nil(@inst.fetch(entry, :missing_element))
    end
end
