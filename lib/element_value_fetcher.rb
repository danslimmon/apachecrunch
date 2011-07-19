class ApacheCrunch
    # Finds a value from an Entry.  Value may be directly from log or derived.
    class ElementValueFetcher
        def initialize
            @_RawValueFetcher = RawValueFetcher
            @_DerivedValueFetcher = DerivedValueFetcher
        end

        # Handles dependency injection
        def dep_inject!(raw_value_fetcher, derived_value_fetcher)
            @_RawValueFetcher = raw_value_fetcher
            @_DerivedValueFetcher = derived_value_fetcher
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
            matching_element = entry.captured_elements.find do |element|
                element_name == element.name
            end

            matching_element ? matching_element.value : nil
        end
    end


    # Returns the value of an element derived from one captured directly from the log.
    class DerivedValueFetcher
        # Returns the value for the given name by deriving from an Element in the Entry.
        #
        # Returns nil if no such value can be derived.
        def fetch(entry, element_name)
            source_element = entry.captured_elements.find do |element|
                element.derivation_rule.derived_elements.include?(element_name)
            end
            return nil if source_element.nil?

            derived_elements = source_element.derivation_rule.derive_all(source_element.value)
            derived_elements[element_name]
        end
    end
end
