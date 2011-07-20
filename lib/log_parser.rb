class ApacheCrunch
    # Parses a log file given a path and a Format instance
    class LogParser
        # Initializes the parser with the path to a log file and a EntryParser.
        def initialize(entry_parser)
            @_entry_parser = entry_parser
            @_log_file = nil

            @_File = File
        end

        # Handles dependency injection
        def dep_inject!(file_cls)
            @_File = file_cls
        end

        # Returns the next parsed line in the log file as an Entry, or nil if we've reached EOF.
        def next_entry
            while line_text = @_log_file.gets
                # This is if we've reached EOF:
                return nil if line_text.nil?

                entry = @_entry_parser.parse(@_format, line_text)
                # The EntryParser returns nil and writes a warning if the line text doesn't
                # match our expected format.
                next if entry.nil?

                return entry
            end
        end

        # Resets the LogParser's filehandle so we can start over.
        def reset_file!
            @_log_file.close
            @_log_file = @_File.open(@_log_file.path)
        end

        # Makes the LogParser start parsing a new log file
        #
        # `new_target` is a writable file object that the parser should start parsing, and if
        # `in_place` is true, we actually replace the contents of the current target with those
        # of the new target.
        def set_file!(new_file)
            @_log_file.close unless @_log_file.nil?
            @_log_file = new_file
        end

        # Replaces the LogParser current file with another. Like, for real, on the filesystem.
        def replace_file!(new_file)
            @_log_file.close
            @_File.rename(new_file.path, @_log_file.path)
            @_log_file = @_File.open(@_log_file.path)
        end

        def set_format!(format)
            @_format = format
        end
    end


    # Makes a LogParser given the parameters we want to work with.
    #
    # This is the class that most external code should instatiate to begin using this library.
    class LogParserFactory
        # Returns a new LogParser instance for the given log file, which should have the given
        # Apache log format.
        def self.log_parser(format_def, path, progress_meter)
            # First we generate a Format instance based on the format definition we were given
            log_format = FormatFactory.from_format_def(format_def)

            # Now we generate a parser for the individual entries
            entry_parser = EntryParser.new
            entry_parser.add_progress_meter!(progress_meter)

            # And now we can instantiate and return a LogParser
            log_parser = LogParser.new(entry_parser)
            log_parser.set_file!(open(path, "r"))
            log_parser.set_format!(log_format)
            log_parser
        end
    end
end
