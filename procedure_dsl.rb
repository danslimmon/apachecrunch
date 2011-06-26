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
        env = CountWhere.new(@_log_parser)
        return env.execute(&blk)
    end

    # DSL keyword 'each'
    def each(&blk)
        env = Each.new(@_log_parser)
        return env.execute(&blk)
    end
end
