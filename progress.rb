class ProgressMeter
    def initialize
        @_entry_count = 0
    end
end


# Progress meter that prints the number of entries parsed every (n) lines.
class EntryCountProgressMeter < ProgressMeter
    def initialize
        # 'period' is how many entries we wait between printing output.  So if 'period' is 10 000,
        # we'll print output every 10 000 lines.
        @_period = 10000
        super
    end

    # Outputs the number of entries that have been parsed so far (every once in a while).
    #
    # 'entry' should be the latest log entry to be parsed, in hash form.
    def output_progress(entry)
        @_entry_count += 1
        if @_entry_count % @_period == 0
            puts "Processed %d entries" % [@_entry_count]
        end
    end
end

class TimeProgressMeter < ProgressMeter
    def initialize
        # 'period' is how many entries we wait between printing output.  So if 'period' is 10 000,
        # we'll print output every 10 000 lines.
        @_period = 10000
        super
    end

    # Outputs the number of entries that have been parsed so far (every once in a while).
    #
    # 'entry' should be the latest log entry to be parsed, in hash form.
    def output_progress(entry)
        @_entry_count += 1
        if @_entry_count % @_period == 0
            puts "Processed through %s" % [entry["time"]]
        end
    end
end

class NullProgressMeter < ProgressMeter
    def output_progress(entry)
    end
end


# Constructs progress meters that output progress info to the user.
class ProgressMeterFactory
    # Constructs a progress meter from a hash containing the options passed on the command line.
    def self.from_options(options)
        pm_class = {
            "entry" => EntryCountProgressMeter,
            "time" => TimeProgressMeter
        }
        pm_class.default = NullProgressMeter

        pm_class[options[:progress]].new
    end
end
