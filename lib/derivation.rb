class ApacheCrunch
    # Abstract for classes that define how to obtain a given element from the value of another.
    class DerivationRule
        # Returns the name of the element from which this rule derives values
        def source_name
            raise NotImplementedError
        end

        # Derives the given derivable element from the given element value
        def derive(name, source_value)
            raise NotImplementedError
        end
    end


    # Dummy rule that doesn't derive anything
    class NullDerivationRule
        def source_name; nil; end
        def target_names; []; end
        def derive(name, source_value); nil; end
    end


    # Derivation rule for elements derived from TimeToken
    class TimeDerivationRule < DerivationRule
        def initialize
            @_derivation_regex = nil
            @_month_map = {"Jan" => 1, "Feb" => 2, "Mar" => 3, "Apr" => 4,
                           "May" => 5, "Jun" => 6, "Jul" => 7, "Aug" => 8,
                           "Sep" => 9, "Oct" => 10, "Nov" => 11, "Dec" => 12}
        end

        def source_name
            :time
        end

        def target_names
            [:year, :month, :day, :hour, :minute, :second]
        end

        def derive(name, source_value)
            if @_derivation_regex.nil?
                @_derivation_regex = Regexp.compile(%q!^\[(\d\d)/([A-Za-z]{3})/(\d\d\d\d):(\d\d):(\d\d):(\d\d)!)
            end

            hsh = {}
            if source_value =~ @_derivation_regex
                hsh[:year] = $3.to_i
                hsh[:month] = @_month_map[$2]
                hsh[:day] = $1.to_i

                hsh[:hour] = $4.to_i
                hsh[:minute] = $5.to_i
                hsh[:second] = $6.to_i
            end

            hsh[name]
        end
    end

    class ReqFirstlineDerivationRule
        def initialize
            @_derivation_regex = nil
        end

        def source_name
            :req_firstline
        end

        def target_names
            [ReqMethodTokenDefinition.name, UrlPathTokenDefinition.name, QueryStringTokenDefinition.name, ProtocolTokenDefinition.name]
        end

        def derive(name, source_value)
            if @_derivation_regex.nil?
                @_derivation_regex = Regexp.compile("^(#{ReqMethodTokenDefinition.regex})\s+(#{UrlPathTokenDefinition.regex})(#{QueryStringTokenDefinition.regex})\s+(#{ProtocolTokenDefinition.regex})$")
            end

            hsh = {}
            if source_value =~ @_derivation_regex
                hsh[ReqMethodTokenDefinition.name] = $1
                hsh[UrlPathTokenDefinition.name] = $2
                hsh[QueryStringTokenDefinition.name] = $3
                hsh[ProtocolTokenDefinition.name] = $4
            end

            hsh[name]
        end
    end

    class DerivationRuleFinder
        @_rule_map = nil
        @_rules = [NullDerivationRule, TimeDerivationRule, ReqFirstlineDerivationRule]

        # Returns a derivation rule that derives element with the given name
        def self.find(element_name)
            @_rule_map = self._build_rule_map if @_rule_map.nil?
            @_rule_map[element_name]
        end

        def self._build_rule_map
            hsh = {}
            @_rules.each do |rule_cls|
                r = rule_cls.new
                r.target_names.each do |target_element|
                    hsh[target_element] = r
                end
            end

            hsh
        end
    end
end
