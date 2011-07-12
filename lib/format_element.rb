# Converts a string to an integer
class IntegerCast
    def self.cast(string_value)
        string_value.to_i
    end
end


# Converts a CLF-formatted string to an integer
#
# "CLF-formatted" means that if the value is 0, the string will be a single hyphen instead of
# a number.  Like %b, for instance.
class CLFIntegerCast
    def self.cast(string_value)
        if string_value == "-"
            return 0
        end
        string_value.to_i
    end
end


# An element in a log format.  Abstract from which all elements inherit.
#
# Exposes:
#    abbrev: The Apache abbreviation for the element (such as "%h" or "%u" or "%{Referer}i")
#    name: A short name for the element (such as "remote_host", "remote_user", or "reqhead_referer")
#    regex: A regex that should match such an element ("[A-Za-z0-9.-]+", "[^:]+", ".+")
#
# If '_caster' is not nil, it should be a class with a method called "cast" that
# transforms a string to the appropriate data type or format for consumption.
# For example, the IntegerCast class transforms "562" to 562.  The correct cast
# of a string can then be performed by passing that string to this LogFormaElement
# instance's "cast" method.
#
# 'derive_elements' manages elements that can be derived from the instance's value.  See
# ReqFirstlineElement for an example.
class LogFormatElement

    attr_accessor :abbrev, :name, :regex, :captured
    # Class variables that determine the _default_ for abbrev, name, and regex in an instance.
    # That is, an instance will initialize with these values for the instance variables @abbrev,
    # @name, and @regex.
    class << self; attr_accessor :abbrev, :name, :regex, :captured end
    # Additionally we need to access this from within the instance:
    class << self; attr_accessor :_caster end

    def initialize
        @abbrev = self.class.abbrev
        @name = self.class.name
        @regex = self.class.regex
        @captured = self.class.captured
    end

    # Casts a string found in the log to the correct type, using the class's @_caster attribute.
    def cast(string_value)
        if _caster.nil?
            return string_value
        else
            return _caster.cast(string_value)
        end
    end

    # Derives the named element (e.g. "url_path") from a given value for this one.
    #
    # See ReqFirstlineElement for an example.
    def self.derive(name, our_own_value)
        raise NotImplementedError
    end

    # Returns a list of the element classes that can be derived from this one.
    #
    # See ReqFirstlineElement for an example.
    def derived_elements
        []
    end
end


# A bare string in a log format.
#
# There shouldn't be anything in @regex except one-to-one character matching.
class StringElement < LogFormatElement
    @captured = false

    def initialize(contents)
        @_contents = contents
        super()
    end

    def regex
        r = @_contents
        # Make sure there aren't any regex special characters in the string that will confuse
        # the EntryParser later.
        '()[].?+{}\\'.each_char do |special_char|
            while r.include?(special_char) do
                r = r.gsub(special_char, '\\' + special_char)
            end
        end
        r
    end
end


class RemoteHostElement < LogFormatElement
    @abbrev = "%h"
    @name = :remote_host
    @regex = %q![A-Za-z0-9.-]+!
    @captured = true
end


class LogNameElement < LogFormatElement
    @abbrev = "%l"
    @name = :log_name
    @regex = %q!\S+!
    @captured = true
end


class RemoteUserElement < LogFormatElement
    @abbrev = "%u"
    @name = :remote_user
    @regex = %q![^:]+!
    @captured = true
end


class TimeElement < LogFormatElement
    @abbrev = "%t"
    @name = :time
    @regex = %q!\[\d\d/[A-Za-z]{3}/\d\d\d\d:\d\d:\d\d:\d\d [-+]\d\d\d\d\]!
    @captured = true

    @_derivation_regex = nil
    @_month_map = {"Jan" => 1, "Feb" => 2, "Mar" => 3, "Apr" => 4, "May" => 5, "Jun" => 6,
                   "Jul" => 7, "Aug" => 8, "Sep" => 9, "Oct" => 10, "Nov" => 11, "Dec" => 12}

    def self.derive(name, our_own_value)
        if @_derivation_regex.nil?
            @_derivation_regex = Regexp.compile(%q!^\[(\d\d)/([A-Za-z]{3})/(\d\d\d\d):(\d\d):(\d\d):(\d\d)!)
        end

        hsh = {}
        if our_own_value =~ @_derivation_regex
            hsh[:year] = $3.to_i
            hsh[:month] = @_month_map[$2]
            hsh[:day] = $1.to_i

            hsh[:hour] = $4.to_i
            hsh[:minute] = $5.to_i
            hsh[:second] = $6.to_i
        end

        hsh[name]
    end

    def derived_elements
        [YearElement, MonthElement, DayElement, HourElement, MinuteElement, SecondElement]
    end
end


# Elements derived from TimeElement
class YearElement < LogFormatElement
    @name = :year
    @regex = %q!\d{4}!
end
class MonthElement < LogFormatElement
    @name = :month
    @regex = %q![A-Za-z]{3}!
end
class DayElement < LogFormatElement
    @name = :day
    @regex = %q!\d{2}!
end
class HourElement < LogFormatElement
    @name = :hour
    @regex = %q!\d{2}!
end
class MinuteElement < LogFormatElement
    @name = :minute
    @regex = %q!\d{2}!
end
class SecondElement < LogFormatElement
    @name = :second
    @regex = %q!\d{2}!
end


class ReqFirstlineElement < LogFormatElement
    @abbrev = "%r"
    @name = :req_firstline
    @regex = %q![^"]+!
    @captured = true

    @_derivation_regex = nil

    def self.derive(name, our_own_value)
        if @_derivation_regex.nil?
            @_derivation_regex = Regexp.compile("^(#{ReqMethodElement.regex})\s+(#{UrlPathElement.regex})(#{QueryStringElement.regex})\s+(#{ProtocolElement.regex})$")
        end

        hsh = {}
        if our_own_value =~ @_derivation_regex
            hsh[ReqMethodElement.name] = $1
            hsh[UrlPathElement.name] = $2
            hsh[QueryStringElement.name] = $3
            hsh[ProtocolElement.name] = $4
        end

        hsh[name]
    end

    def derived_elements
        return [ReqMethodElement, UrlPathElement, QueryStringElement, ProtocolElement]
    end
end


class StatusElement < LogFormatElement
    @abbrev = "%s"
    @name = :status
    @regex = %q!\d+|-!
    @captured = true
end


class BytesSentElement < LogFormatElement
    @abbrev = "%b"
    @name = :bytes_sent
    @regex = %q!\d+!
    @captured = true

    @@_caster = IntegerCast
end


class BytesSentElement < LogFormatElement
    @abbrev = "%b"
    @name = :bytes_sent
    @regex = %q![\d-]+!
    @captured = true

    @_caster = CLFIntegerCast
end


class BytesSentWithHeadersElement < LogFormatElement
    @abbrev = "%O"
    @name = :bytes_sent_with_headers
    @regex = %q!\d+!
    @captured = true

    @_caster = IntegerCast
end


class ServeTimeMicroElement < LogFormatElement
    @abbrev = "%D"
    @name = :serve_time_micro
    @regex = %q!\d+!
    @captured = true

    @_caster = IntegerCast
end


class UrlPathElement < LogFormatElement
    @abbrev = "%U"
    @name = :url_path
    @regex = %q!/[^?]*!
    @captured = true
end


class QueryStringElement < LogFormatElement
    @abbrev = "%q"
    @name = :query_string
    @regex = %q!\??\S*!
    @captured = true
end


class ReqMethodElement < LogFormatElement
    @abbrev = "%m"
    @name = :req_method
    @regex = %q![A-Z]+!
    @captured = true
end


class ProtocolElement < LogFormatElement
    @abbrev = "%H"
    @name = :protocol
    @regex = %q!\S+!
    @captured = true
end


class ReqheaderElement < LogFormatElement
end


class RegexElement < LogFormatElement
end


# Finds log format elements given information about them.
class ElementDictionary
    @@_ELEMENTS = [
                    RemoteHostElement,
                    LogNameElement,
                    RemoteUserElement,
                    TimeElement,
                    ReqFirstlineElement,
                    StatusElement,
                    BytesSentElement,
                    BytesSentElement,
                    BytesSentWithHeadersElement,
                    ServeTimeMicroElement,
                    UrlPathElement,
                    QueryStringElement,
                    ReqMethodElement,
                    ProtocolElement
    ]

    # Returns the LogFormatElement subclass with the given format-string abbreviation.
    #
    # If none exists, returns nil.
    def self.find_by_abbrev(abbrev)
        @@_ELEMENTS.each do |element|
            if element.abbrev == abbrev
                return element
            end
        end

        nil
    end
end


# Generates LogFormatElement instances.
#
# This class does the work of figuring out which LogFormatElement subclass to make and makes it.
class LogFormatElementFactory
    # Takes an Apache log format abbreviation and returns a corresponding LogFormatElement
    def from_abbrev(abbrev)
        element_cls = ElementDictionary.find_by_abbrev(abbrev)
        if element_cls
            # We found it in the dictionary, so just return an instance
            return element_cls.new
        elsif abbrev =~ /^%\{([A-Za-z0-9-]+)\}i/
            # HTTP request header
            return _reqheader_element(abbrev, $1)
        elsif abbrev =~ /^%\{(.*?):([^}]+)\}r/
            # Arbitrary regex
            return _regex_element(abbrev, $1, $2)
        end

        raise "Unknown element format '#{abbrev}'"
    end

    # Returns a LogFormatElement subclass instance based on a static string.
    #
    # This element not be captured by the EntryParser since it's always the same.
    def from_string(s)
        StringElement.new(s)
    end

    # Returns a format element based on an HTTP header
    def _reqheader_element(abbrev, header_name)
        element = ReqheaderElement.new

        element.abbrev = abbrev
        element.regex = %q![^"]*!
        element.name = _header_name_to_element_name(header_name)

        element
    end

    # Returns a format element based on an arbitrary regex
    def _regex_element(abbrev, regex_name, regex)
        element = RegexElement.new

        element.abbrev = abbrev
        element.regex = regex
        element.name = "regex_#{regex_name}".to_sym

        element
    end

    # Lowercases header name and turns hyphens into underscores
    def _header_name_to_element_name(header_name)
        ("reqheader_" + header_name.downcase().gsub("-", "_")).to_sym
    end
end