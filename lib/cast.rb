class ApacheCrunch
    # Converts a string to an integer
    class IntegerCast
        def cast(string_value)
            string_value.to_i
        end
    end

    # Converts a CLF-formatted string to an integer
    #
    # "CLF-formatted" means that if the value is 0, the string will be a single hyphen instead of
    # a number.  Like %b, for instance.
    class CLFIntegerCast
        def cast(string_value)
            if string_value == "-"
                return 0
            end
            string_value.to_i
        end
    end
end
