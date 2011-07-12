require 'test/stub'

class TestFormatParser < Test::Unit::TestCase
    def setup
        @inst = ApacheCrunch::FormatParser.new(StubLogFormatElementFactory.new,
                                               StubFormatString)
    end

    def teardown
        @inst = nil
    end

    def test_parse_simple
        tokens = @inst.parse_def("%Z %z")
        [StubFormatElement, StubFormatString, StubFormatElement].each_with_index do |c,i|
            assert_instance_of(c, tokens[i])
        end
    end

    def test_parse_complex
        tokens = @inst.parse_def("%{Foo-Bar}i %{baz:\d+}r")
        [StubFormatElement, StubFormatString, StubFormatElement].each_with_index do |c,i|
            assert_instance_of(c, tokens[i])
        end
    end
end
