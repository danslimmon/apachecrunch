require 'test/mock'

class TestFormat < Test::Unit::TestCase
    def setup
        @inst = ApacheCrunch::Format.new
    end

    def teardown
        @inst = nil
    end

    def test_captured_tokens
        tokens = [
            StubAlphanumericFormatToken.new,
            StubStringFormatToken.new("foo"),
            StubNumericFormatToken.new,
            StubStringFormatToken.new("bar"),
            StubAlphanumericFormatToken.new
        ]

        @inst.tokens = tokens
        assert_equal([tokens[0], tokens[2], tokens[4]], @inst.captured_tokens,
                     "#{@inst.class}#captured_tokens returned the wrong list of captured tokens")
    end
end
