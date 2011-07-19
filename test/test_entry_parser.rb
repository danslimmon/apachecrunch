require 'test/stub'

class TestEntryParser < Test::Unit::TestCase
    def setup
        @inst = ApacheCrunch::EntryParser.new
        @format = StubFormat.new
        @format.tokens = [StubAlphanumericFormatToken.new,
                          StubStringFormatToken.new(" stuff "),
                          StubNumericFormatToken.new]
    end

    def teardown
        @inst = nil
    end

    # Tests a successful parse call
    def test_parse
        line_text = "hurrdurr stuff 01560"
        @inst.dep_inject!(StubEntry, StubElement)

        result = @inst.parse(@format, line_text)
        assert_instance_of(StubEntry, result,
                           "#{@inst.class}#parse returned wrong type of thing")
    end

    # Tests a parse call on a malformatted line
    def test_parse_fail
        line_text = "slammadamma doesn't match"
        @inst.dep_inject!(StubEntry, StubElement)

        $VERBOSE = nil
        result = @inst.parse(@format, line_text)
        $VERBOSE = true
        assert_nil(result, "#{@inst.class}#parse returned non-nil for malformmated line")
    end
end
