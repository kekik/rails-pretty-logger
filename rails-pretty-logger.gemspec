$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "rails/pretty/logger/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "rails-pretty-logger"
  s.version     = Rails::Pretty::Logger::VERSION
  s.authors     = ["Cem"]
  s.email       = ["cbaykam@gmail.com"]
  s.homepage    = "https://github.com/kekik/rails-pretty-logger"
  s.summary     = ": Summary of Rails::Pretty::Logger."
  s.description = ": Description of Rails::Pretty::Logger."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "~> 5.0"
  s.add_development_dependency 'sqlite3', '~> 1.3', '>= 1.3.6'
  s.add_development_dependency 'rspec-rails', "~> 3.6"
end
