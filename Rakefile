# frozen_string_literal: true

task default: %i[test lint]

task test: %i[spec]
task lint: %i[rubocop]

require 'bundler/gem_tasks'

require 'rdoc/task'
RDoc::Task.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'Rails::PrettyLogger'
  rdoc.options << '--line-numbers'
  rdoc.rdoc_files.include('README.md')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |t|
  t.ruby_opts = %w[-W2]
  t.verbose = false
end

desc 'alias for the "spec" task'

require 'rubocop/rake_task'
RuboCop::RakeTask.new(:rubocop) do |t|
  t.options = %w[--config ./.rubocop.yaml --color]
end
