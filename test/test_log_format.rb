class LogFormat_StubFormatElement < LogFormatElement
    @abbrev = "%z"
    @name = :stub
    @regex = %q!.*!
end

class LogFormat_AlphanumericFormatElement < LogFormatElement
    @abbrev = "%Z"
    @name = :alnum
    @regex = %q![A-Za-z0-9]+!
end

class LogFormat_NumericFormatElement < LogFormatElement
    @abbrev = "%y"
    @name = :num
    @regex = %q!\d+!
end

class LogFormat_FormatString
    attr_accessor :regex
    def initialize(regex)
        @regex = regex
    end
end


class TestLogFormat < Test::Unit::TestCase
    def setup
        @inst = LogFormat.new
    end

    def teardown
        @inst = nil
    end

    # Tests appending an element to the format
    def test_append
        format_element = LogFormat_StubFormatElement.new
        @inst.append(format_element)
        assert_same(@inst.tokens[-1], format_element)
    end

    # Tests regex compilation for a simple format
    def test_simple
        @inst.append(LogFormat_AlphanumericFormatElement.new)
        "abc123\n" =~ @inst.regex
        assert_equal($1, "abc123")

        "!abc123\n" =~ @inst.regex
        assert_nil($1)
    end

    # Tests regex compilation for a more complex format
    def test_complex
        @inst.append(LogFormat_NumericFormatElement.new)
        @inst.append(LogFormat_FormatString.new(' \(some stuff\) '))
        @inst.append(LogFormat_AlphanumericFormatElement.new)

        "54321 (some stuff) alphaNumericStuff" =~ @inst.regex
        assert_equal([Regexp.last_match(1), Regexp.last_match(2)],
                      ["54321", "alphaNumericStuff"])

        "54321 (doesn't match) alphaNumericStuff" =~ @inst.regex
        assert_equal([Regexp.last_match(1), Regexp.last_match(2)],
                      [nil, nil])
    end
end
