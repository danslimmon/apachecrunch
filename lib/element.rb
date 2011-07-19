class ApacheCrunch
    class Element
        attr_accessor :token, :value

        def populate!(token, value)
            @token = token
            @value = value
        end

        def name; @token.name; end

        def derivation_rule
            if @token.respond_to?(:token_definition)
                return @token.token_definition.derivation_rule
            else
                return nil
            end
        end
    end
end
