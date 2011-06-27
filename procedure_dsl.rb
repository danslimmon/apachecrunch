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


# DSL keyword that returns the number of log entries where the block evaluates to true
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


# DSL keyword that executes the block for every log entry
class Each < ProcedureRoutine
    def execute(&blk)
        while @_current_entry = @_log_parser.next_entry
            instance_eval(&blk)
        end
    end
end


# DSL keyword that filters for entries for which the given block evaluates to true
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

# DSL keyword that returns the count of entries with each found value of the given block
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

    # DSL keyword 'count_where'
    def count_where(&blk)
        routine = CountWhere.new(@_log_parser)
        rv = routine.execute(&blk)
        routine.finish
        rv
    end

    # DSL keyword 'filter!'
    def filter!(&blk)
        routine = FilterInPlace.new(@_log_parser)
        routine.execute(&blk)
        routine.finish
        nil
    end

    # DSL keyword 'each'
    def each(&blk)
        routine = Each.new(@_log_parser)
        routine.execute(&blk)
        routine.finish
        nil
    end

    # DSL keyword 'count_by'
    def count_by(&blk)
        routine = CountBy.new(@_log_parser)
        rv = routine.execute(&blk)
        routine.finish
        rv
    end
end
