require 'test/stub'

class TestTimeDerivationRule < Test::Unit::TestCase
    def setup
        @inst = ApacheCrunch::TimeDerivationRule.new
    end

    def teardown
        @inst = nil
    end

    # Tests that the expected list of derived elements matches what actually gets derived
    def test_derived_elements
        expected_names = @inst.derived_elements
        result = @inst.derive_all("[15/Jul/2011:09:55:41 +0400]")

        expected_names.each do |name|
            assert(result.key?(name),
                   "#{@inst.class}#derive_all is missing one or more elements")
        end

        expected_values = {
            :year => 2011,
            :month => 7,
            :day => 15,
            :hour => 9,
            :minute => 55,
            :second => 41
        }

        expected_names.each do |name|
            assert_equal(result[name], expected_values[name],
                         "#{@inst.class}#derive_all returned incorrect value for element #{name}")
        end
    end
end
