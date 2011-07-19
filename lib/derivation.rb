class ApacheCrunch
    # Abstract for classes that define how to obtain a given element from the value of another.
    class DerivationRule
        # Returns the names of all elements that can be derived with this rule
        def derived_elements
            raise NotImplementedError
        end

        # Derives all derivable elements from the given string value
        #
        # Returns a hash mapping derived element name to derived value
        def derive_all(source_value)
        end
    end


    # Derivation rule for elements derived from TimeToken
    class TimeDerivationRule < DerivationRule
        def derived_elements
            [:year, :month, :day, :hour, :minute, :second]
        end

        def derive_all(value)
            if @_derivation_regex.nil?
                @_derivation_regex = Regexp.compile(%q!^\[(\d\d)/([A-Za-z]{3})/(\d\d\d\d):(\d\d):(\d\d):(\d\d)!)
            end

            if @_month_map.nil?
                @_month_map = {"Jan" => 1, "Feb" => 2, "Mar" => 3, "Apr" => 4,
                               "May" => 5, "Jun" => 6, "Jul" => 7, "Aug" => 8,
                               "Sep" => 9, "Oct" => 10, "Nov" => 11, "Dec" => 12}
            end

            hsh = {}
            if value =~ @_derivation_regex
                hsh[:year] = $3.to_i
                hsh[:month] = @_month_map[$2]
                hsh[:day] = $1.to_i

                hsh[:hour] = $4.to_i
                hsh[:minute] = $5.to_i
                hsh[:second] = $6.to_i
            end

            hsh
        end
    end

    class ReqFirstlineDerivationRule
        def derived_elements
            return [:req_method, :url_path, :query_string, :protocol]
        end

        def derive_all(value)
            if @_derivation_regex.nil?
                @_derivation_regex = Regexp.compile("^(#{ReqMethodToken.regex})\s+(#{UrlPathToken.regex})(#{QueryStringToken.regex})\s+(#{ProtocolToken.regex})$")
            end

            hsh = {}
            if value =~ @_derivation_regex
                hsh[ReqMethodToken.name] = $1
                hsh[UrlPathToken.name] = $2
                hsh[QueryStringToken.name] = $3
                hsh[ProtocolToken.name] = $4
            end

            hsh
        end
    end
end