class ApacheCrunch
    # A parsed entry from the log.
    #
    # Acts like a hash, in that you get at the log elements (e.g. "url_path", "remote_host") by
    # as entry[name].
    class Entry
        def initialize(derivation_map)
            @_derivation_map = derivation_map
            @_attributes = {}
        end

        def []=(name, value)
            @_attributes[name] = value
        end

        def [](name)
            return @_attributes[name] if @_attributes.key?(name)

            derived_from_cls = @_derivation_map[name]
            return nil if derived_from_cls.nil?

            derived_from_cls.derive(name, @_attributes[derived_from_cls.name])
        end

        def merge!(hsh)
            @_attributes.merge!(hsh)
        end
    end


    # Makes Entry instances based on log file text
    class EntryParser
        # Initializes the instance given a LogFormat instance
        def initialize(log_format, progress_meter)
            @log_format = log_format
            @progress_meter = progress_meter

            @_elements = log_format.captured_elements
            @_derivation_map = log_format.derivation_map
        end

        # Returns a log line hash built from a line of text, or nil if the line was malformatted
        #
        # The keys of the hash are names of FormatElements (e.g. "remote_host", "reqheader_referer")
        def parse(log_text)
            match = (log_text =~ @log_format.regex)
            if match.nil?
                warn "Log line did not match expected format: #{log_text}"
                return nil
            end
            
            # Make a hash mapping all parsed elements to their values in the entry
            match_groups = Regexp.last_match.to_a
            match_groups.shift # First value is the whole matched string, which we do not want
            element_values = Hash[*@_elements.zip(match_groups).flatten]

            # Start building the return value
            entry = Entry.new(@_derivation_map)
            entry[:text] = log_text
            # Insert all the elements specified in the LogFormat
            entry.merge!(_elements_to_hash(element_values))

            @progress_meter.output_progress(entry)
            entry
        end

        # Returns a hash of "element name" => value pairs based on a hash of element => value pairs.
        def _elements_to_hash(element_values)
            hsh = {}
            element_values.each_pair do |element, value|
                hsh[element.name] = value
            end

            hsh
        end

        # Returns hash of derived "element name" => value pairs from a hash of element => value pairs.
        #
        # That is, we go through the elements passed and if any offers derived elements, we include
        # those in the return value.
        def _derived_elements(element_values)
            hsh = {}
            element_values.each_pair do |element, value|
                hsh.merge!(element.derived_values(value))
            end

            hsh
        end
    end
end
