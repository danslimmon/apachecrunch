class ApacheCrunch
    class Element
        attr_accessor :token, :value

        def populate!(token, value)
            @token = token
            @value = value
        end

        def name; @token.name; end

        def derivation_rule
            @token.derivation_rule
        end
    end
end
