#!/usr/bin/env ruby
require 'test/unit'

$: << ".."
$: << "./lib"
require 'apachecrunch'

class ParticularTests
    def self.run(tests)
        tests.each do |test_file|
            require test_file
        end
    end
end

class AllTests
    def self.run
        Dir.glob("test/test_*.rb").each do |test_file|
            require test_file
        end
    end
end

if ARGV.length > 0
    ParticularTests.run(ARGV)
else
    AllTests.run
end
