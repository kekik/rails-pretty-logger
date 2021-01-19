# frozen_string_literal: true

require_relative 'lib/rails/pretty_logger/version'

Gem::Specification.new do |spec|
  spec.name         = 'rails-pretty_logger'
  spec.version      = Rails::PrettyLogger::VERSION
  spec.authors      = %w[Cem Mehmet]
  spec.email        = %w[cbaykam@gmail.com mehmetcelik4@gmail.com]

  spec.summary      = 'A mountable engine that makes checking Rails logs easier'
  spec.description  = 'PrettyLogger is a mountable Rails engine that helps '\
                      'checking logs from a Ruby on Rails application easier. '\
                      'It supports highlighting a string of your choosing to '\
                      'easily spot what you seek. It is also possible to perform '\
                      'hourly log rotation.'
  spec.homepage     = 'https://github.com/kekik/rails-pretty_logger'
  spec.license      = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.5.0')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] =
    "#{spec.metadata['source_code_uri']}/blob/master/CHANGELOG.md"

  spec.files          = Dir['{app,config,lib}/**/*', 'CHANGELOG.md',
                            'LICENSE.txt', 'README.md']
  spec.require_paths  = ['lib']

  spec.add_dependency 'rails', ['>= 6.1.1', '< 7']
  {
    # rubocop:disable Layout/HashAlignment
    'bundler':                ['>= 2.2.5', '< 3'],
    'rake':                   ['>= 13.0.3', '< 14'],
    'rdoc':                   ['>= 6.3.0', '< 7'],
    'rspec':                  ['>= 3.10.0', '< 4'],
    'rspec-rails':            ['>= 4.0.2', '< 5'],
    'rubocop':                ['>= 1.8.1', '< 2'],
    'rubocop-packaging':      ['>= 0.5.1', '< 1'],
    'rubocop-performance':    ['>= 1.9.2', '< 2'],
    'rubocop-rails':          ['>= 2.9.1', '< 3'],
    'rubocop-rake':           ['>= 0.5.1', '< 1'],
    'rubocop-rspec':          ['>= 2.1.0', '< 3'],
    'rubocop-thread_safety':  ['>= 0.4.2', '< 1'],
    'sqlite3':                ['>= 1.4.2', '< 2'],
    # rubocop:enable Layout/HashAlignment
  }.each_pair { |dep, ver| spec.add_development_dependency dep, ver }
end
