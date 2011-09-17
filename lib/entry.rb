require 'element'
require 'progress'

class ApacheCrunch
    # A parsed entry from the log.
    #
    # Acts like a hash, in that you get at the log elements (e.g. "url_path", "remote_host") by
    # as entry[name].
    class Entry
        attr_accessor :captured_elements

        def initialize
            @captured_elements = {}
            @_value_fetcher = nil

            @_ElementValueFetcher = ElementValueFetcher
        end

        def dep_inject!(element_value_fetcher_cls)
            @_ElementValueFetcher = element_value-fetcher_cls
        end

        def fetch(name)
            @_value_fetcher = @_ElementValueFetcher.new if @_value_fetcher.nil?
            @_value_fetcher.fetch(self, name)
        end
    end


    # Makes Entry instances based on log file text
    class EntryParser
        # Initializes the instance given a ProgressMeter instance
        def initialize
            @_Entry = Entry
            @_Element = Element
            
            @_progress_meter = NullProgressMeter.new
            @_regex = nil
        end

        # Handles dependency injection
        def dep_inject!(entry_cls, element_cls)
            @_Entry = entry_cls
            @_Element = element_cls
        end

        # Applies the given ProgressMeter to the parser so that it will output progress.
        #
        # The meter's output_progress method will get called every time we finish parsing
        # a log entry.
        def add_progress_meter!(meter)
            @_progress_meter = meter
        end

        # Returns an Entry instance built from a line of text, or nil if the line was malformatted
        def parse(format, log_text)
            @_regex = _build_regex(format) if @_regex.nil?

            match = (log_text =~ @_regex)
            if match.nil?
                warn "Log line did not match expected format: #{log_text.rstrip}"
                return nil
            end

            match_groups = Regexp.last_match.to_a
            match_groups.shift # First value is the whole matched string, which we do not want

            entry = @_Entry.new
            format.captured_tokens.each_with_index do |tok,i|
                 entry.captured_elements[tok.name] = match_groups[i]
            end

            @_progress_meter.output_progress(entry)
            entry
        end

        def _build_regex(format)
            r = "^"
            format.tokens.each do |tok|
                # We only care to remember the captured LogFormatElements.  No need to put
                # parentheses around StringElements that aren't interpolated.
                if tok.captured?
                    r += "(" + tok.regex + ")"
                else
                    r += tok.regex
                end
            end
            r += "$"

            Regexp.compile(r)
        end
    end
end
