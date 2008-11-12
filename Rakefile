
require 'rubygems'

require 'rake'
require 'rake/clean'
require 'rake/packagetask'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rake/testtask'

require 'lib/rufus/gversion' # Rufus::Google::VERSION

#
# GEM SPEC

spec = Gem::Specification.new do |s|

  s.name = 'rufus-google'
  s.version = Rufus::Google::VERSION
  s.authors = [ 'John Mettraux' ]
  s.email = 'john at gmail dot com'
  s.homepage = 'http://rufus.rubyforge.org/rufus-google'
  s.platform = Gem::Platform::RUBY
  s.summary = 'snippets of Ruby code for accessing Google stuff'
  #s.license = 'MIT'
  s.rubyforge_project = 'rufus'

  s.require_path = 'lib'
  #s.autorequire = 'rufus-whatever'
  s.test_file = 'test/test.rb'
  s.has_rdoc = true
  s.extra_rdoc_files = [ 'README.txt' ]

  [ 'rufus-verbs', 'atom-tools' ].each do |d|
    s.requirements << d
    s.add_dependency d
  end

  files = FileList[ "{bin,lib,test}/**/*" ]
  files.exclude 'rdoc'
  s.files = files.to_a
end

#
# tasks

CLEAN.include('pkg', 'html')

task :default => [ :clean, :repackage ]


#
# TESTING

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.test_files = FileList['test/test.rb']
  t.verbose = true
end

#
# PACKAGING

Rake::GemPackageTask.new(spec) do |pkg|
  #pkg.need_tar = true
end

Rake::PackageTask.new('rufus-google', Rufus::Google::VERSION) do |pkg|
  pkg.need_zip = true
  pkg.package_files = FileList[
    'Rakefile',
    '*.txt',
    'lib/**/*',
    'test/**/*'
  ].to_a
  #pkg.package_files.delete("MISC.txt")
  class << pkg
    def package_name
      "#{@name}-#{@version}-src"
    end
  end
end

#
# DOCUMENTATION

#ALLISON=`allison --path`
#ALLISON="/Library/Ruby/Gems/1.8/gems/allison-2.0.3/lib/allison.rb"

Rake::RDocTask.new do |rd|

  rd.main = 'README.txt'

  rd.rdoc_dir = 'html/rufus-google'

  rd.rdoc_files.include(
    'README.txt',
    'CHANGELOG.txt',
    'LICENSE.txt',
    'CREDITS.txt',
    'lib/**/*.rb')

  rd.title = 'rufus-google rdoc'

  rd.options << '-N' # line numbers
  rd.options << '-S' # inline source

  #rd.template = ALLISON if File.exist?(ALLISON)
end


#
# WEBSITE

task :upload_website => [ :clean, :rdoc ] do

  account = 'jmettraux@rubyforge.org'
  webdir = '/var/www/gforge-projects/rufus'

  sh "rsync -azv -e ssh html/rufus-google #{account}:#{webdir}/"
end

