source "https://rubygems.org"

# Declare this gem's runtime dependencies in rails-pretty-logger.gemspec.
gemspec

if ENV["RAILS_VERSION"]
  gem "rails", ENV.fetch("RAILS_VERSION")
else
  gem "rails", ">= 7.1", "< 9.0"
end

gem "capybara"
gem "capybara-playwright-driver"
gem "propshaft"
gem "puma"

# Start debugger with binding.b.
# gem "debug", ">= 1.0.0"
