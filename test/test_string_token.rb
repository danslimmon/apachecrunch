require 'test/stub'

class TestStringToken < Test::Unit::TestCase
    def setup
        @inst = ApacheCrunch::StringToken.new
    end

    def teardown
        @inst = nil
    end

    def test_regex
        datasets = [
            [' ', '\ '],
            [' {has (regex [chars', '\ \{has\ \(regex\ \[chars']
        ]

        datasets.each do |ds|
            string_value = ds[0]
            expected_regex = ds[1]

            @inst.populate!(string_value)
            assert_equal(expected_regex, @inst.regex,
                         "#{@inst.class}#regex returned incorrect value")
        end
    end
end
