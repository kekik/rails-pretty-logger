require "bundler/setup"
require "rake/testtask"

Rake::TestTask.new(:test) do |test|
  test.libs << "test"
  test.pattern = "test/**/*_test.rb"
end

require "bundler/gem_tasks"
load "lib/tasks/rails/pretty/logger_tasks.rake"

task default: :test
