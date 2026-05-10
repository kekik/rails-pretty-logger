require_relative "lib/rails/pretty/logger/version"

Gem::Specification.new do |spec|
  spec.name        = "rails-pretty-logger"
  spec.version     = Rails::Pretty::Logger::VERSION
  spec.authors     = ["Cem Baykam", "Mehmet Celik"]
  spec.email       = ["cbaykam@gmail.com", "mehmetcelik4@gmail.com"]
  spec.summary     = "Rails engine for browsing and highlighting application logs."
  spec.description = "Rails Pretty Logger provides a mounted dashboard for browsing log files, highlighting entries, clearing logs, and reading hourly rotated log files."
  spec.homepage    = "https://github.com/MehmetCelik4/rails-pretty-logger"
  spec.license     = "MIT"
  spec.required_ruby_version = ">= 3.1"
  spec.metadata    = {
    "source_code_uri" => spec.homepage,
    "changelog_uri" => "#{spec.homepage}/releases"
  }

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,lib}/**/*", "MIT-LICENSE", "README.md"]
  end

  spec.add_dependency "actionpack", ">= 7.1", "< 9.0"
  spec.add_dependency "actionview", ">= 7.1", "< 9.0"
  spec.add_dependency "activesupport", ">= 7.1", "< 9.0"
  spec.add_dependency "railties", ">= 7.1", "< 9.0"

  spec.add_development_dependency "minitest", "~> 5.0"
end
