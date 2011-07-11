#!/usr/bin/env ruby
require 'test/unit'

$: << ".."
$: << "./lib"
require 'apachecrunch'

Dir.glob("test/test_*.rb").each do |test_file|
    require test_file
end
