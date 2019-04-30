$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "rails/pretty/logger/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "rails-pretty-logger"
  s.version     = Rails::Pretty::Logger::VERSION
  s.authors     = ["Cem", "Mehmet"]
  s.email       = ["cbaykam@gmail.com", "mehmetcelik4@gmail.com"]
  s.homepage    = "https://github.com/kekik/rails-pretty-logger"
  s.summary     = "Pretty Logger is a logging framework which can be checked from '/your-web-page/rails-pretty-logger/dashboards',
   can also debug easily with highlight method. And can add Hourly log rotation."
  s.description = "Check and search your logs from page, hightlight it to spot easily, add hourly rotation if you wish. "
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "~> 5.0"
  s.add_development_dependency 'sqlite3', '~> 1.3', '>= 1.3.6'
  s.add_development_dependency 'rspec-rails', "~> 3.6"
  s.required_ruby_version = '>= 2.2.2'
end
