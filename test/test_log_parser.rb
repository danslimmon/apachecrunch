require 'test/stub'
require 'test/mock'

class TestLogParser < Test::Unit::TestCase
    def setup
        @entry_parser = StubEntryParser.new
        @inst = ApacheCrunch::LogParser.new(@entry_parser)
    end

    def teardown
        @inst = nil
    end

    # Tests setting the log file to a given file
    def test_set_file
        first_log_file = MockFile.new
        assert_nothing_thrown("#{@inst.class}#set_file! threw an exception") do
            @inst.set_file!(first_log_file)
        end

        second_log_file = MockFile.new
        assert_nothing_thrown("#{@inst.class}#set_file! threw an exception") do
            @inst.set_file!(second_log_file)
        end
        assert_equal(1, first_log_file.close_count,
                     "#{@inst.class}#set_file! didn't close old file")
    end

    # Tests replacing the log file with another file
    def test_replace_file
        mock_file_class = MockFileClass.new
        @inst.dep_inject!(mock_file_class)

        first_log_file = MockFile.new
        first_log_file.path = "/first/path"
        @inst.set_file!(first_log_file)

        second_log_file = MockFile.new
        second_log_file.path = "/second/path"
        assert_nothing_thrown("#{@inst.class}#replace_file! threw an exception") do
            @inst.replace_file!(second_log_file)
        end
        assert_equal([["/second/path", "/first/path"]], mock_file_class.rename_calls,
                     "#{@inst.class}#replace_file! didn't move the file into place")
        assert_equal(1, first_log_file.close_count,
                     "#{@inst.class}#replace_file! didn't close old file")
    end

    # Tests resetting the log file to its beginning
    def test_reset_file
        mock_file_class = MockFileClass.new
        @inst.dep_inject!(mock_file_class)

        log_file = MockFile.new
        @inst.set_file!(log_file)

        assert_nothing_thrown("#{@inst.class}#reset_file! threw an exception") do
            @inst.reset_file!
        end
        assert_equal(1, log_file.close_count,
                     "#{@inst.class}#reset_file! didn't close the log file")
        assert_equal(1, mock_file_class.open_calls.length,
                     "#{@inst.class}#reset_file! didn't reopen the log file")
    end

    # Tests retrieving the next entry in the log
    def test_next_entry
        @entry_parser.parse_return_values = [
            StubEntry.new,
            StubEntry.new,
            nil,
            StubEntry.new
        ]

        log_file = MockFile.new
        log_file.lines = ["a\n", "b\n", "c\n", "d\n"]

        @inst.set_file!(log_file)
        @inst.set_format!(StubFormat.new)
        assert_instance_of(StubEntry, @inst.next_entry,
                           "#{@inst.class}#next_entry returned wrong type of thing")
        assert_instance_of(StubEntry, @inst.next_entry,
                           "#{@inst.class}#next_entry returned wrong second value")
        assert_instance_of(StubEntry, @inst.next_entry,
                           "#{@inst.class}#next_entry returned wrong value when it should have skipped a malformatted entry")
        assert_nil(@inst.next_entry, "#{@inst.class}#next_entry returned non-nil at EOF")
    end
end
