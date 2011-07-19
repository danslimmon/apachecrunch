class ApacheCrunch
    class ElementFetcher
        def initialize(raw_element_fetcher_cls=RawElementFetcher,
                       derived_element_fetcher_cls=DerivedElementFetcher)
            @_RawElementFetcher = raw_element_fetcher_cls
            @_DerivedElementFetcher = derived_element_fetcher_cls

            @_raw_fetcher = @_RawElementFetcher.new
            @_derived_element_fetcher = @_DerivedElementFetcher.new
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

    class RawElementFetcher
        def fetch(entry, element_name)
            entry.captured_elements.find do |element|
                element_name == element.name
            end
        end
    end

    class DerivedElementFetcher
        def fetch(entry, element_name)
            entry.elements.each do |element|
                puts "Hey"
            end
        end
    end
end
