require "rake"

spec = Gem::Specification.new do |s|
    s.name = "apachecrunch"
    s.version = "0.4"
    s.summary = "Apache log analysis tool designed for ease of use"
    s.description = %q!Apache Crunch is an analysis tool for Apache logs.  You write little scripts
to do the analysis, using our DSL to make the procedure as simple and readable
as possible.  See our homepage for more details.!

    s.authors = ["Dan Slimmon"]
    s.email = "dan@danslimmon.com"
    s.homepage = "https://github.com/danslimmon/apachecrunch/"
    s.license = "Creative Commons Share-Alike"
    
    s.executables = ["apachecrunch"]
    s.files = FileList['lib/**/*.rb', 'bin/*', '[A-Z]*', 'test/**/*'].to_a
end
