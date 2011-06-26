#!/usr/bin/ruby

require "apache_log"
require "procedure_dsl"

procedure_path = ARGV[0]
log_path = ARGV[1]

parser = LogParserFactory.log_parser(
                        format_string=%q!%h %l %u %t "%r" %s %b "%{Referer}i" "%{User-agent}i"!,
                        path=log_path)
proc_env = ProcedureEnvironment.new(parser)
proc_env.eval_procedure(open(procedure_path).read())
