require 'test/stub'

class TestFormat < Test::Unit::TestCase
    def setup
        @inst = ApacheCrunch::Format.new
    end

    def teardown
        @inst = nil
    end

    # Tests appending an element to the format
    def test_append
        format_element = StubFormatElement.new
        @inst.append(format_element)
        assert_same(@inst.tokens[-1], format_element)
    end

    # Tests regex compilation for a simple format
    def test_regex_simple
        @inst.append(StubAlphanumericFormatElement.new)
        "abc123\n" =~ @inst.regex
        assert_equal($1, "abc123")

        "!abc123\n" =~ @inst.regex
        assert_nil($1)
    end

    # Tests regex compilation for a more complex format
    def test_regex_complex
        @inst.append(StubNumericFormatElement.new)
        @inst.append(StubFormatString.new(' \(some stuff\) '))
        @inst.append(StubAlphanumericFormatElement.new)

        "54321 (some stuff) alphaNumericStuff" =~ @inst.regex
        assert_equal([Regexp.last_match(1), Regexp.last_match(2)],
                      ["54321", "alphaNumericStuff"])

        "54321 (doesn't match) alphaNumericStuff" =~ @inst.regex
        assert_equal([Regexp.last_match(1), Regexp.last_match(2)],
                      [nil, nil])
    end

    # Tests the list of matchable elements
    def test_elements
        num_element = StubNumericFormatElement.new
        alnum_element = StubAlphanumericFormatElement.new
        @inst.append(num_element)
        @inst.append(StubFormatString.new(' \(some stuff\) '))
        @inst.append(alnum_element)

        assert_equal(@inst.elements, [num_element, alnum_element])
    end

    # Tests the derivation map
    def test_derivation_map
        @inst.append(StubNumericFormatElement.new)
        @inst.append(StubFormatString.new(' \(some stuff\) '))
        @inst.append(StubDerivationSourceElement.new)

        assert(@inst.derivation_map, {:derived => StubDerivationSourceElement})
    end
end
