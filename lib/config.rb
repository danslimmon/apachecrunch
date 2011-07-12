class ApacheCrunch
    # Finds a named log format string in the configuration file(s)
    class FormatDefinitionFinder
        @@FILE_NAME = "log_formats.rb"
        @@DEFAULT_FORMATS = {
            :ncsa => %q!%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-agent}i\"!,
            :ubuntu => %q!%h %l %u %t \"%r\" %>s %O \"%{Referer}i\" \"%{User-Agent}i\"!
        }

        # Initializes the FormatStringFinder.
        def initialize(file_cls=File, env=ENV)
            @_file_cls=file_cls
            @_env=env
        end

        # Finds the given format string in the configuration file(s)
        #
        # If none exists, returns nil.
        def find(format_name)
            name_as_symbol = format_name.to_sym

            formats = @@DEFAULT_FORMATS.clone
            _search_path.each do |dir|
                config_path = @_file_cls.join(dir, @@FILE_NAME)
                if @_file_cls.readable?(config_path)
                    config_file = @_file_cls.open(@_file_cls.join(dir, @@FILE_NAME))
                    eval config_file.read
                end

                if formats.key?(format_name.to_sym)
                    return formats[format_name.to_sym].gsub(/\\"/, '"')
                end
            end

            raise "Failed to find the format '#{format_name}' in the search path: #{_search_path.inspect}"
        end

        def _search_path
            [".", "./etc",
             @_file_cls.join(@_env["HOME"], ".apachecrunch"),
             "/etc/apachecrunch"]
        end
    end
end
