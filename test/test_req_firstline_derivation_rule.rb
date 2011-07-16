require 'test/stub'

class TestReqFirstlineDerivationRule < Test::Unit::TestCase
    def setup
        @inst = ApacheCrunch::ReqFirstlineDerivationRule.new
    end

    def teardown
        @inst = nil
    end

    def test_derived_elements
        expected_names = @inst.derived_elements
        datasets = [
            ["GET / HTTP/1.1", {:req_method => "GET",
                                :url_path => "/",
                                :query_string => "",
                                :protocol => "HTTP/1.1"}],
            ["HEAD /?herp=derp&foo=bar HTTP/1.0", {:req_method => "HEAD",
                                                   :url_path => "/",
                                                   :query_string => "?herp=derp&foo=bar",
                                                   :protocol => "HTTP/1.0"}],
            ["POST /some/page?never=gonna HTTP/1.1", {:req_method => "POST",
                                                      :url_path => "/some/page",
                                                      :query_string => "?never=gonna",
                                                      :protocol => "HTTP/1.1"}]
        ]

        expected_names = @inst.derived_elements
        datasets.each do |ds|
            firstline_value = ds[0]
            expected_values = ds[1]
            result = @inst.derive_all(firstline_value)

            expected_names.each do |name|
                assert(result.key?(name),
                       "#{@inst.class}#derive_all is missing one or more elements")
            end


            expected_names.each do |name|
                assert_equal(expected_values[name], result[name],
                             "#{@inst.class}#derive_all returned wrong value for element #{name}")
            end
        end
    end
end
