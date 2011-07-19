require 'test/stub'

class TestElement < Test::Unit::TestCase
    def setup
        @inst = ApacheCrunch::Element.new
    end

    def teardown
        @inst = nil
    end

    # Tests a successful derivation_rule call
    def test_derivation_rule
        @inst.populate!(StubDerivationSourceToken.new, "bar456")
        assert_instance_of(StubDerivationRule, @inst.derivation_rule,
                           "#{@inst.class}#derivation_rule returned wrong type of thing")
    end
end
