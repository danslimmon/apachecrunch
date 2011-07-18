class TestReqheaderToken < Test::Unit::TestCase
    def setup
        @inst = ApacheCrunch::RegexToken.new
    end

    def teardown
        @inst = nil
    end

    # Tests that the token figures out its name correctly from the header
    def test_name
        @inst.populate!("foobar", "[A-Za-z0-9]+")

        assert_equal(:regex_foobar, @inst.name,
                     "#{@inst.class} got wrong name based on regex name 'foobar'")
    end
end
