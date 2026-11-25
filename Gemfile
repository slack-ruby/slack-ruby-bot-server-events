# frozen_string_literal: true

source 'https://rubygems.org'

case ENV.fetch('DATABASE_ADAPTER', nil)
when 'mongoid'
  # ActiveSupport before 8.1, which older Mongoid versions resolve to, is incompatible with json 3.
  gem 'json', '< 3'
  gem 'kaminari-mongoid'
  gem 'mongoid', ENV['MONGOID_VERSION'] || '~> 7.6.0'
  gem 'mongoid-scroll'
  gem 'mutex_m'
when 'activerecord'
  gem 'activerecord'
  gem 'otr-activerecord'
  gem 'pagy_cursor'
  gem 'pg'
  gem 'virtus'
when nil
  warn "Missing ENV['DATABASE_ADAPTER']."
else
  warn "Invalid ENV['DATABASE_ADAPTER']: #{ENV.fetch('DATABASE_ADAPTER', nil)}."
end

gemspec

group :development, :test do
  gem 'bundler'
  gem 'danger-changelog', require: false
  gem 'danger-pr-comment', require: false
  gem 'danger-toc', require: false
  gem 'database_cleaner'
  gem 'fabrication'
  gem 'faker'
  gem 'hyperclient'
  gem 'ostruct'
  gem 'rack-test'
  gem 'rake'
  gem 'rspec'
  gem 'vcr'
  gem 'webmock'
  if RUBY_ENGINE == 'ruby' && Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('3.3')
    gem 'rubocop', '~> 1.92'
    gem 'rubocop-md', '~> 3.0', require: false
    gem 'rubocop-prose', '~> 0.2', require: false
    gem 'rubocop-rake', '~> 0.7', require: false
    gem 'rubocop-rspec', '~> 3.10', require: false
    gem 'rubocop-spellcheck', '~> 0.2', require: false
    gem 'rubocop-yaml', '~> 0.1.0', require: false
  end
end
