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


# DSL routine(s) that filter(s) for entries for which the given block evaluates to true
#
# This can be called as 'filter()', which means the filtering happens in a temporary file, or
# as 'filter(path)', which means the filtering happens in the given file.  It can also be called
# as 'filter!()', which means the filtering happens in place, clobbering what's in apachecrunch's
# target file.
class Filter < ProcedureRoutine
    def execute(path=nil, in_place=false, &blk)
        @_in_place = in_place
        @_results_file = _make_results_file(path, in_place)

        while @_current_entry = @_log_parser.next_entry
            if instance_eval(&blk)
                @_results_file.write(@_current_entry["text"])
            end
        end
    end

    def finish
        @_log_parser.replace_target(@_results_file, @_in_place)
    end

    # Returns a writable file object to which the results of the filter should be written.
    def _make_results_file(path, in_place)
        if path.nil?
            # If no path passed (this includes the case where the filter is being performed
            # in place), we want a temp file.
            return Tempfile.new("apachecrunch")
        else
            return open(path, "w")
        end
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


# Same as Distribution, but the buckets get expenentially wider
class LogDistribution < ProcedureRoutine
    def execute(width_base, &blk)
        dist = {}
        while @_current_entry = @_log_parser.next_entry
            val = instance_eval(&blk)
            k = _key_for(val, width_base)
            if dist.key?(k)
                dist[k] += 1
            else
                dist[k] = 1
            end
        end

        # Backfill keys for which we didn't find a value
        k = dist.keys.min
        max_key = dist.keys.max
        while k *= width_base and k < max_key
            dist[k] = 0 unless dist.key?(k)
        end

        dist
    end

    # Determines the key for the distribution hash given the value and logarithmic base for
    # the bucket width
    def _key_for(val, width_base)
        exp = (Math.log(val) / Math.log(width_base)).to_i
        width_base ** exp
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
        routine = Filter.new(@_log_parser)
        routine.execute(nil, true, &blk)
        routine.finish
        nil
    end

    # DSL routine 'filter'
    def filter(target_path=nil, &blk)
        routine = Filter.new(@_log_parser)
        routine.execute(target_path, &blk)
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

    # DSL routine 'log_distribution'
    def log_distribution(width_base, &blk)
        routine = LogDistribution.new(@_log_parser)
        rv = routine.execute(width_base, &blk)
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
