require 'test/stub'

class MockFile
    attr_accessor :gets, :path, :close_count, :lines
    def initialize
        @close_count = 0
    end
    def close
        @close_count += 1
    end
    def gets
        @lines.shift
    end
end

# Pretends to be Ruby's File class but just logs what it's asked to do
class MockFileClass
    attr_accessor :rename_calls, :open_calls
    def initialize
        @rename_calls = []
        @open_calls = []
    end
    def rename(*args); @rename_calls << args; end
    def open(*args); @open_calls << args; end
end

# Pretends to be a FormatTokenFactory class but just logs what it's asked to do
class MockFormatTokenFactoryClass
    attr_accessor :from_abbrev_calls
    def initialize
        @from_abbrev_calls = []
    end
    def from_abbrev(*args)
        @from_abbrev_calls << args
        StubAlphanumericFormatToken.new
    end
end
