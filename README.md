# Rails::Pretty::Logger

Pretty Logger is a Rails engine for checking application logs from a mounted dashboard. It supports Rails 7.1+ and Rails 8, highlighted log entries, clearing log files, and optional hourly log rotation.

## Usage
visit http://your-webpage/rails-pretty-logger/dashboards/ then choose your log file, search with date range.
![](log_file.gif)

#### How to use debug Highlighter

```
PrettyLogger.highlight("lorem ipsum")
```
![](highlight.gif)

#### Use Hourly Log Rotation

Add these lines below to environment config file which you want to override its logger, first argument for name of the log file, second argument for keeping hourly logs, file count for limiting the logs files.

Rails::Pretty::Logger::ConsoleLogger.new("rails-pretty-logger", "hourly", file_count: 48)

```  
#/config/environments/development.rb

require "rails/pretty/logger/config/logger_config"

logger_file = ActiveSupport::TaggedLogging.new(Rails::Pretty::Logger::ConsoleLogger.new("rails-pretty-logger", "hourly", file_count: 48))
config.logger = logger_file
```   
![](hour.gif)

#### Split your old logs by hourly

If you want split your old log files by hourly you can use this rake task below at terminal

argument takes what will be new files names start with, and with the second one will take the full path of your log file which will be splitted

for bash usage ```rake app:split_log["new_log_file_name","/path/to/your/log.file"]```

for zch usage  ```noglob rake app:split_log["new_log_file_name","/path/to/your/log.file"]```

## Installation
Add this line to your application's Gemfile:

```
gem "rails-pretty-logger"
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install rails-pretty-logger
```
Mount the engine in your config/routes.rb:

```
mount Rails::Pretty::Logger::Engine => "/rails-pretty-logger"
```

## Contributing

This project uses a Nix flake and direnv for local development:

```bash
direnv allow
bundle install
bundle exec rails test
bundle exec ruby -Itest test/system/rails_pretty_logger_interaction_test.rb
```

CI runs the same test suite against Rails 7.1, 7.2, and 8.0 before PRs and pushes to `main` or `master`.

1. [Fork][fork] the [official repository][repo].
2. [Create a topic branch.][branch]
3. Implement your feature or bug fix.
4. Add, commit, and push your changes.
5. [Submit a pull request.][pr]

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).


[repo]: https://github.com/MehmetCelik4/rails-pretty-logger/tree/master
[fork]: https://help.github.com/articles/fork-a-repo/
[branch]: https://help.github.com/articles/creating-and-deleting-branches-within-your-repository/
[pr]: https://help.github.com/articles/using-pull-requests/
