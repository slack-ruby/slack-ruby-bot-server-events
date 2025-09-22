# frozen_string_literal: true

source 'https://rubygems.org'

case ENV.fetch('DATABASE_ADAPTER', nil)
when 'mongoid'
  gem 'kaminari-mongoid'
  gem 'mongoid', ENV['MONGOID_VERSION'] || '~> 7.3.0'
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
  gem 'database_cleaner'
  gem 'fabrication'
  gem 'faker'
  gem 'hyperclient'
  gem 'rack-test'
  gem 'rake'
  gem 'rspec'
  gem 'rubocop', '1.80.2'
  gem 'rubocop-rake'
  gem 'rubocop-rspec'
  gem 'vcr'
  gem 'webmock'
end
