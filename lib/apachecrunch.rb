require "date"
require "tempfile"

require 'config'
require 'entry'
require 'format'
require 'log_parser'
require 'log_element'

class ApacheCrunch
    # A bare string in a log format
    #
    # Exposes 'regex' for consistency with LogFormatElement, but there shouldn't be anything other
    # than one-to-one character matching in there.
    class LogFormatString
        attr_accessor :regex

        def initialize(regex)
            @regex = regex
        end
    end
end
