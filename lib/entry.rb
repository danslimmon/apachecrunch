require 'element'

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
        # Initializes the instance given a ProgressMeter instance
        def initialize(format, progress_meter, entry_cls=Entry, element_cls=Element)
            @_format = format
            @_progress_meter = progress_meter

            @_Entry = entry_cls
            @_Element = element_cls
        end

        # Returns an Entry instance built from a line of text, or nil if the line was malformatted
        def parse(log_text)
            @_regex = _build_regex(@_format) unless @_regex

            match = (log_text =~ @_regex)
            if match.nil?
                warn "Log line did not match expected format: #{log_text.rstrip}"
                return nil
            end

            match_groups = Regexp.last_match.to_a
            match_groups.shift # First value is the whole matched string, which we do not want

            entry = @_Entry.new
            @_format.tokens.each_with_index do |tok,i|
                if tok.captured?
                    e = @_Element.new
                    e.populate!(tok, match_groups[i])
                    entry.add_element(e)
                end
            end

            @progress_meter.output_progress(entry)
            entry
        end

        def _build_regex(format)
            r = "^"
            @format.tokens.each do |tok|
                # We only care to remember the captured LogFormatElements.  No need to put
                # parentheses around StringElements that aren't interpolated.
                if tok.captured?
                    r += "(" + tok.regex + ")"
                else
                    r += tok.regex
                end
            end
            r += "$"

            r
        end
    end
end
