class ApacheCrunch
    # Finds a value from an Entry.  Value may be directly from log or derived.
    class ElementValueFetcher
        def initialize
            @_RawValueFetcher = RawValueFetcher
            @_DerivedValueFetcher = DerivedValueFetcher
        end

        # Handles dependency injection
        def dep_inject!(raw_value_fetcher_cls, derived_value_fetcher_cls)
            @_RawValueFetcher = raw_value_fetcher_cls
            @_DerivedValueFetcher = derived_value_fetcher_cls
        end

        # Returns the value of the element with the given name from the Entry instance.
        #
        # So element_name might be :minute or :reqheader_firstline for instance.
        def fetch(entry, element_name)
            v = @_RawValueFetcher.new.fetch(entry, element_name)
            return v unless v.nil?

            v = @_DerivedValueFetcher.new.fetch(entry, element_name)
            return v unless v.nil?

            nil
        end
    end


    # Returns the value of an element that was captured straight from the log.
    class RawValueFetcher
        # Returns the value of the Element with the given name in the given Entry.
        #
        # Only works for elements based on tokens that we parsed directly into the Entry.  If no
        # matching element is found, we return nil.
        def fetch(entry, element_name)
            entry.captured_elements[element_name].value
        end
    end


    # Returns the value of an element derived from one captured directly from the log.
    class DerivedValueFetcher
        def initialize
            @_DerivationRuleFinder = DerivationRuleFinder
        end

        # Handles dependency injection
        def dep_inject!(derivation_rule_finder_cls)
            @_DerivationRuleFinder = derivation_rule_finder_cls
        end

        # Returns the value for the given name by deriving from an Element in the Entry.
        #
        # Returns nil if no such value can be derived.
        def fetch(entry, element_name)
            # Find the derivation rule that will get us the element we want
            rule = @_DerivationRuleFinder.find(element_name)
            return nil if rule.nil?
            
            # Get the value of the element from which we're deriving
            source_element_name = rule.source_name
            source_element = entry.captured_elements[source_element_name]
            return nil if source_element.nil?

            # Do the derivation
            rule.derive(element_name, source_element.value)
        end
    end
end
