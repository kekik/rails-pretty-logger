# Rails::Pretty::Logger

Rails Pretty Logger is a Rails engine for browsing application logs from a mounted dashboard. The current line supports Ruby 3.3+, Rails 7.1, and Rails 8, with log filtering, tailing, request grouping, structured JSON rendering, safe clear actions, and optional hourly log rotation.

## Index

- [Feature overview](#feature-overview)
- [Compatibility](#compatibility)
- [Installation](#installation)
- [Usage](#usage)
- [Dashboard security](#dashboard-security)
- [Configuration](#configuration)
- [Custom log formats](#custom-log-formats)
- [Highlighting](#highlighting)
- [Hourly log rotation](#hourly-log-rotation)
- [Performance and safety](#performance-and-safety)
- [Dependency policy](#dependency-policy)
- [Asset loading](#asset-loading)
- [Development and CI](#development-and-ci)
- [License](#license)

## Feature overview

- Mounted Rails engine dashboard for files under `Rails.root/log`.
- Main log and hourly rotated log browsers.
- Date range filtering, content search, severity filtering, and configurable pagination.
- Tail mode that reads the last configured number of lines without loading the whole file.
- Rails request grouping for `Started ...` / `Completed ...` log blocks.
- Structured JSON line rendering with extracted timestamp, severity, message, and metadata.
- Custom parser hook for non-standard log formats.
- English and Turkish locale files.
- `[HIGHLIGHT]` helper support for visually marked log entries.
- Clear log actions with `read_only` protection.
- Safe log file resolution that rejects missing files, invalid paths, and paths outside the app log directory.
- Optional file size guard for large logs.
- Memory and disk-backed line offset indexes for faster pagination and request grouping after the first scan.

## Compatibility

| Gem version | Ruby | Rails | Notes |
| --- | --- | --- | --- |
| `0.3.x` | `>= 3.3` | `>= 7.1`, `< 9.0` | Current line. CI runs Rails 7.1, 8.0, and 8.1 with Ruby 3.3. |
| `0.2.8` | `>= 2.2.2` | `>= 5.0`, `<= 6.1.4.1` | Legacy line for older Rails apps. Pin this version if you still need Rails 5 or Rails 6.1 support. |

## Installation

Add this line to your application's Gemfile:

```ruby
gem "rails-pretty-logger"
```

For Rails 5 or Rails 6.1 applications, pin the legacy version:

```ruby
gem "rails-pretty-logger", "0.2.8"
```

Then install the bundle:

```bash
bundle install
```

Run the install generator:

```bash
bin/rails generate rails_pretty_logger:install
```

The generator creates `config/initializers/rails_pretty_logger.rb`, mounts the engine in `config/routes.rb`, and links the engine JavaScript in `app/assets/config/manifest.js` when the host app has a Sprockets manifest.

You can also mount the engine manually:

```ruby
mount Rails::Pretty::Logger::Engine => "/rails-pretty-logger"
```

## Usage

Visit `/rails-pretty-logger` or `/rails-pretty-logger/dashboards` after mounting the engine. The exact prefix depends on the path you choose in `config/routes.rb`.

The dashboard can:

- list regular log files from `log/`;
- list hourly rotated files from `log/hourly/`;
- filter log lines by date range, content query, and severity;
- switch between paginated view and tail view;
- group standard Rails request logs;
- render JSON line logs as structured entries;
- clear selected logs when `read_only` is disabled.

Severity filtering recognizes `DEBUG`, `INFO`, `WARN`, `ERROR`, `FATAL`, and `UNKNOWN`. For structured JSON logs it checks `severity`, `level`, `log_level`, and nested `log.level` values.

## Dashboard security

Rails Pretty Logger does not provide its own authentication system. The dashboard can read application logs and, unless `read_only` is enabled, clear log files. Do not expose it publicly without protecting the mount.

For local-only use, mount it only in development:

```ruby
# config/routes.rb
mount Rails::Pretty::Logger::Engine => "/rails-pretty-logger" if Rails.env.development?
```

For protected environments, use the authentication or authorization your application already has:

```ruby
# config/initializers/rails_pretty_logger.rb
Rails::Pretty::Logger.configure do |config|
  config.authenticate_with = -> { authenticate_user! }
end
```

The hook runs inside the engine controller, so application controller helpers such as `authenticate_user!`, `current_user`, `head`, and `redirect_to` are available when your app defines them. For apps without an admin model, keep the engine development-only or use whichever internal access check already exists in the app.

## Configuration

Rails Pretty Logger can be configured from an initializer:

```ruby
# config/initializers/rails_pretty_logger.rb
Rails::Pretty::Logger.configure do |config|
  config.authenticate_with = -> { authenticate_user! }
  config.read_only = Rails.env.production?
  config.max_file_size = 50.megabytes
  config.tail_lines = 500
  config.log_line_parser = nil
end
```

| Option | Default | Description |
| --- | --- | --- |
| `authenticate_with` | `nil` | Optional callable run before every engine action. |
| `read_only` | `true` in production, `false` elsewhere | Hides clear buttons and returns `403 Forbidden` from clear endpoints. |
| `max_file_size` | `nil` in the gem, `50.megabytes` in the generated initializer | Returns `413 Payload Too Large` instead of reading files above the limit. |
| `tail_lines` | `500` | Number of lines shown in tail mode. |
| `log_line_parser` | `nil` | Optional callable for extracting metadata from custom log lines. |

## Custom log formats

JSON line logs are detected automatically when each line is a JSON object. Common keys such as `@timestamp`, `timestamp`, `time`, `datetime`, `created_at`, `severity`, `level`, `log_level`, `message`, and `msg` are rendered prominently. Other JSON keys are shown as metadata.

For non-JSON formats, configure a parser that returns metadata for lines it understands:

```ruby
Rails::Pretty::Logger.configure do |config|
  config.log_line_parser = ->(line) do
    if (match = line.match(/\A(?<timestamp>\S+) (?<severity>\w+) (?<method>[A-Z]+) (?<path>\S+) (?<message>.*)/))
      {
        timestamp: match[:timestamp],
        severity: match[:severity],
        request_method: match[:method],
        request_path: match[:path]
      }
    end
  end
end
```

Supported parser keys include `:timestamp`, `:time`, `:datetime`, `:created_at`, `:severity`, `:level`, `:log_level`, `:request_method`, `:method`, `:request_path`, `:path`, `:request_ip`, `:ip`, `:request_started_at`, `:started_at`, `:response_status`, `:status`, `:duration`, and `:request_duration`.

These keys power date filtering, severity filtering, request grouping, and request summaries.

## Highlighting

Use the helper below to write a highlighted log entry:

```ruby
Rails::Pretty::Logger::PrettyLogger.highlight("lorem ipsum")
```

Highlighted lines are written with the `[HIGHLIGHT]` tag and rendered with dashboard highlight styling.

## Hourly log rotation

Rails Pretty Logger can replace the Rails logger with a logger that rotates files hourly:

```ruby
# config/environments/development.rb
require "rails/pretty/logger/console_logger"

config.logger = ActiveSupport::TaggedLogging.new(
  Rails::Pretty::Logger::ConsoleLogger.new("rails-pretty-logger", "hourly", file_count: 48)
)
```

Hourly files are moved under `log/hourly/YYYY/MM/DD/`. `file_count` controls how many rotated hourly files are kept for that logger prefix. Rotation uses a lock file under `tmp/rails_pretty_logger/` and removes empty date directories when old hourly files are deleted.

To split an existing log file into hourly files, use the rake task below. The first argument is the new file prefix and the second argument is the full path of the log file to split.

For bash:

```bash
bin/rails 'split_log[new_log_file_name,/path/to/your/log.file]'
```

For zsh:

```zsh
noglob bin/rails split_log[new_log_file_name,/path/to/your/log.file]
```

## Performance and safety

Log file paths are resolved under `Rails.root/log`; invalid paths, missing files, and symlinks that escape the log directory are rejected.

Paginated reads and request grouping use line offset indexes instead of keeping the full selected page in memory. Indexes are cached in memory and persisted under `tmp/cache/rails_pretty_logger/line_indexes`. Cache entries are keyed by the file signature, filters, and parser identity, and clear actions invalidate the related indexes.

The first index build still scans the selected log once. Tail mode avoids that cost when you only need the latest entries because it reads backwards from the end of the file.

## Dependency policy

Runtime dependencies are limited to Rails framework gems:

- `actionpack`
- `actionview`
- `activesupport`
- `railties`

The dashboard JavaScript is plain JavaScript and does not require a runtime Node package manager dependency. Browser tests use Playwright only in development/test.

## Asset loading

The engine layout loads its JavaScript directly with `javascript_include_tag "rails/pretty/logger/application"`. The install generator links this file in `app/assets/config/manifest.js` when the host app has a Sprockets manifest.

Importmap pins are not generated because the engine does not use the host app's JavaScript entrypoint. For standard Rails asset pipeline apps, no manual importmap setup is needed. If your app has a custom asset setup or strict CSP, make sure `rails/pretty/logger/application.js` is available through the asset pipeline and allowed by your policy.

## Development and CI

This project uses a Nix flake and direnv for local development. After allowing direnv once, commands run inside the project shell automatically:

```bash
direnv allow
bundle install
bundle exec rails test
bundle exec ruby -Itest test/system/rails_pretty_logger_interaction_test.rb
gem build rails-pretty-logger.gemspec
```

System tests use Capybara with Playwright Chromium.

GitHub Actions runs on pull requests and pushes to `main` or `master`. The CI matrix runs Rails 7.1, 8.0, and 8.1 on Ruby 3.3, then executes Ruby tests, browser tests, and gem build checks inside the Nix shell.

1. [Fork][fork] the [official repository][repo].
2. [Create a topic branch.][branch]
3. Implement your feature or bug fix.
4. Add, commit, and push your changes.
5. [Submit a pull request.][pr]

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

[repo]: https://github.com/kekik/rails-pretty-logger/tree/master
[fork]: https://help.github.com/articles/fork-a-repo/
[branch]: https://help.github.com/articles/creating-and-deleting-branches-within-your-repository/
[pr]: https://help.github.com/articles/using-pull-requests/
