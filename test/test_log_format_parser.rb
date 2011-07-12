require 'test/stub'

class TestLogFormatParser < Test::Unit::TestCase
    def setup
        @inst = LogFormatParser.new(StubLogFormatElementFactory.new,
                                    StubFormatString)
    end

    def teardown
        @inst = nil
    end

    def test_parse_simple
        tokens = @inst.parse_string("%Z %z")
        [StubFormatElement, StubFormatString, StubFormatElement].each_with_index do |c,i|
            assert_instance_of(c, tokens[i])
        end
    end

    def test_parse_complex
        tokens = @inst.parse_string("%{Foo-Bar}i %{baz:\d+}r")
        [StubFormatElement, StubFormatString, StubFormatElement].each_with_index do |c,i|
            assert_instance_of(c, tokens[i])
        end
    end
end
