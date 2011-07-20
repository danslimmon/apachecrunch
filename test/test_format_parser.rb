require 'test/mock'

class TestFormatParser < Test::Unit::TestCase
    def setup
        @inst = ApacheCrunch::FormatParser.new
    end

    def teardown
        @inst = nil
    end

    def test_parse
        datasets = [
            ["%a %b", [["%a"], [" "], ["%b"]]],
            ["%a bare string %{Request-Header}i",
                [["%a"], [" bare string "], ["%{Request-Header}i"]]],
            ["%{foo:[A-Za-z0-9]}r %% %a %b",
                [["%{foo:[A-Za-z0-9]}r"], [" "], ["%%"], [" "], ["%a"], [" "], ["%b"]]]
        ]

        datasets.each do |dataset|
            format_def = dataset[0]
            from_abbrev_calls = dataset[1]

            mock_format_token_factory = MockFormatTokenFactoryClass.new
            @inst.dep_inject!(mock_format_token_factory)

            result = @inst.parse_def(format_def).length
            assert_equal(from_abbrev_calls, mock_format_token_factory.from_abbrev_calls,
                         "#{@inst.class}#parse_def didn't call FormatTokenFactory with right parameters")
            assert_equal(from_abbrev_calls.length, result,
                         "#{@inst.class}#parse_def didn't return right number of tokens")
        end
    end
end
