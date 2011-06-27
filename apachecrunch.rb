#!/usr/bin/ruby

require "apache_log"
require "procedure_dsl"


# Prints the usage message and exits with the given exit code
def barf_usage(exit_code)
    puts "USAGE:
    apachecrunch.rb <PROCEDURE> <LOG> [--format <FORMAT>]"
    exit exit_code
end


# Parses arguments
#
# Returns a hash with these keys (as symbols):
#   procedure: The path to the procedure DSL file
#   logfile: The path to the log file
#   format: The name of the log format specified ("ncsa" by default)
def parse_args
    args = ARGV.clone
    options = {}

    # Defaults
    options[:format] = "ncsa"

    while a = args.shift
        if a == "--format"
            options[:format] = args.shift
        elsif a == "--help"
            barf_usage(0)
        elsif options.key?(:procedure)
            options[:logfile] = a
        else
            options[:procedure] = a
        end
    end
    unless options.key?(:procedure) and options.key?(:logfile)
        barf_usage(1)
    end

    return options
end


options = parse_args

format_string = FormatStringFinder.new.find(options[:format])
log_parser = LogParserFactory.log_parser(
                        format_string=format_string,
                        path=options[:logfile])
proc_env = ProcedureEnvironment.new(log_parser)
proc_env.eval_procedure(open(options[:procedure]).read())
