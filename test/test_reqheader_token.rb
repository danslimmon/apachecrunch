class TestReqheaderToken < Test::Unit::TestCase
    def setup
        @inst = ApacheCrunch::ReqheaderToken.new
    end

    def teardown
        @inst = nil
    end

    # Tests that the token figures out its name correctly from the header
    def test_name
        datasets = [
            ['Host', :reqheader_host],
            ['X-Two-Words', :reqheader_x_two_words]
        ]

        datasets.each do |ds|
            header_name = ds[0]
            expected_token_name = ds[1]

            @inst.populate!(header_name)
            assert_equal(expected_token_name, @inst.name,
                         "#{@inst.class} got wrong name based on header name '#{header_name}'")
        end
    end
end
