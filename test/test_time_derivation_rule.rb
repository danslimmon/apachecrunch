require 'test/stub'

class TestTimeDerivationRule < Test::Unit::TestCase
    def setup
        @inst = ApacheCrunch::TimeDerivationRule.new
    end

    def teardown
        @inst = nil
    end

    # Tests that the expected list of derived elements matches what actually gets derived
    def test_derive
        expected_names = [:year, :month, :day, :hour, :minute, :second]
        expected_values = {
            :year => 2011,
            :month => 7,
            :day => 15,
            :hour => 9,
            :minute => 55,
            :second => 41
        }

        expected_names.each do |name|
            assert_equal(expected_values[name], @inst.derive(name, "[15/Jul/2011:09:55:41 +0400]"),
                         "#{@inst.class}#derive_all returned incorrect value for element #{name}")
        end
    end
end
