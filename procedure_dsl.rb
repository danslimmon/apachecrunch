# Abstract for a procedure routine.
class ProcedureRoutine
    def initialize(log_parser)
        @_log_parser = log_parser
        @_current_entry = nil
    end

    # Allows blocks passed to a DSL routine to access parameters from the current log entry
    def method_missing(sym, *args)
        @_current_entry[sym.to_s]
    end

    # Executes the DSL routine using the given block
    #
    # Abstract method
    def execute(&blk)
        raise "Not implemented"
    end

    # Anything that needs to happen after the routine completes but before it returns its
    # result can go in here.
    def finish
        @_log_parser.reset
    end
end


# DSL routine that returns the number of log entries where the block evaluates to true
class CountWhere < ProcedureRoutine
    def execute(&blk)
        count = 0
        while @_current_entry = @_log_parser.next_entry
            if instance_eval(&blk)
                count += 1
            end
        end
        count
    end
end


# DSL routine that executes the block for every log entry
class Each < ProcedureRoutine
    def execute(&blk)
        while @_current_entry = @_log_parser.next_entry
            instance_eval(&blk)
        end
    end
end


# DSL routine that filters for entries for which the given block evaluates to true
#
# The filter happens in place, so the contents of the analyzed log file will be replaced with
# only the lines that match the filter.
class FilterInPlace < ProcedureRoutine
    def execute(&blk)
        @_rep_file = @_log_parser.begin_replacement if @replacement_file.nil?

        while @_current_entry = @_log_parser.next_entry
            if instance_eval(&blk)
                @_rep_file.write(@_current_entry["text"])
            end
        end
    end

    def finish
        @_log_parser.replace
    end
end

# DSL routine that returns the count of entries with each found value of the given block
#
# You might for instance run this with the block { status }, and you'd get back something like
# {"200" => 941, "301" => 41, "404" => 2, "500" => 0}
class CountBy < ProcedureRoutine
    def execute(&blk)
        counts = {}
        while @_current_entry = @_log_parser.next_entry
            val = instance_eval(&blk)
            if counts.key?(val)
                counts[val] += 1
            else
                counts[val] = 1
            end
        end
        return counts
    end
end


# DSL routine that finds the distribution of (numeric) values to which the given block evaluates
#
# For example,
#
#     distribution 100 do
#         bytes_sent
#     end
# 
# would return a hash with keys from 0 up by multiples of 100, the value of each being the number
# of entries for which bytes_sent is between that key and the next key.
class Distribution < ProcedureRoutine
    def execute(bucket_width, &blk)
        dist = {}
        while @_current_entry = @_log_parser.next_entry
            val = instance_eval(&blk)
            k = _key_for(val, bucket_width)
            if dist.key?(k)
                dist[k] += 1
            else
                dist[k] = 1
            end
        end

        # Backfill keys for which we didn't find a value
        0.step(dist.keys.max, bucket_width).each do |k|
            dist[k] = 0 unless dist.key?(k)
        end

        dist
    end

    # Determines the key for the distribution hash given the value and step
    def _key_for(val, bucket_width)
        (val.to_i / bucket_width) * bucket_width
    end
end


# DSL routine that determines a confidence interval for the values to which the block evaluates
#
# For example,
#
#     confidence_interval 95 do
#         time_to_serve
#     end
#
# would return two numbers, the lower and upper bound of a 95% confidence interval for the values
# of time_to_serve.
class ConfidenceInterval < ProcedureRoutine
    def execute(confidence, &blk)
        # Build a list of all the values found
        values = []
        while @_current_entry = @_log_parser.next_entry
            values << instance_eval(&blk)
        end
        values.sort!

        # Determine how many values are outside the bounds of the CI
        count_outside = (values.length * (1.0 - confidence/100.0)).to_i

        # Find the bounds of the confidence interval
        return values[count_outside / 2], values[-count_outside / 2]
    end
end


# The environment in which a procedure file is evaluated.
#
# A procedure file is some ruby code that uses our DSL.
class ProcedureEnvironment
    def initialize(log_parser)
        @_log_parser = log_parser
    end

    # Evaluates the given string as a procedure in our DSL
    def eval_procedure(proc_string)
        eval proc_string
    end

    # DSL routine 'count_where'
    def count_where(&blk)
        routine = CountWhere.new(@_log_parser)
        rv = routine.execute(&blk)
        routine.finish
        rv
    end

    # DSL routine 'filter!'
    def filter!(&blk)
        routine = FilterInPlace.new(@_log_parser)
        routine.execute(&blk)
        routine.finish
        nil
    end

    # DSL routine 'each'
    def each(&blk)
        routine = Each.new(@_log_parser)
        routine.execute(&blk)
        routine.finish
        nil
    end

    # DSL routine 'count_by'
    def count_by(&blk)
        routine = CountBy.new(@_log_parser)
        rv = routine.execute(&blk)
        routine.finish
        rv
    end

    # DSL routine 'distribution'
    def distribution(bucket_width, &blk)
        routine = Distribution.new(@_log_parser)
        rv = routine.execute(bucket_width, &blk)
        routine.finish
        rv
    end

    # DSL routine 'confidence_interval'
    def confidence_interval(confidence, &blk)
        routine = ConfidenceInterval.new(@_log_parser)
        rv = routine.execute(confidence, &blk)
        routine.finish
        rv
    end
end
