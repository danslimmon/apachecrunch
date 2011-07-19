class ApacheCrunch
    class ElementValueFetcher
        def initialize(raw_value_fetcher=RawValueFetcher,
                       derived_value_fetcher_cls=DerivedValueFetcher)
            @_RawValueFetcher = raw_value_fetcher_cls
            @_DerivedValueFetcher = derived_value_fetcher_cls

            @_raw_fetcher = @_RawValueFetcher.new
            @_derived_element_fetcher = @_DerivedValueFetcher.new
        end

        # Returns the value of the element with the given name from the Entry instance.
        #
        # So element_name might be :minute or :reqheader_firstline for instance.
        def fetch(entry, element_name)
            v = @_raw_fetcher.fetch(entry, element_name)
            return v unless v.nil?

            v = @_derived_fetcher.fetch(entry, element_name)
            return v unless v.nil?

            nil
        end
    end

    class RawValueFetcher
        def fetch(entry, element_name)
            matching_element = entry.captured_elements.find do |element|
                element_name == element.name
            end

            matching_element ? matching_element.value : nil
        end
    end

    class DerivedValueFetcher
        def fetch(entry, element_name)
            entry.captured_elements.each do |element|
                dr = element.derivation_rule
                if dr.derived_elements.include?(element_name)
                    derived_elements = dr.derive_all(element.value)
                    return derived_elements[element_name]
                end
            end

            nil
        end
    end
end
