# frozen_string_literal: true

source 'https://rubygems.org'

case ENV['DATABASE_ADAPTER']
when 'mongoid' then
  gem 'kaminari-mongoid'
  gem 'mongoid'
  gem 'mongoid-scroll'
when 'activerecord' then
  gem 'activerecord'
  gem 'otr-activerecord'
  gem 'virtus'
  gem 'cursor_pagination', github: 'dblock/cursor_pagination', branch: 'misc' # rubocop:disable Bundler/OrderedGems
  gem 'pg'
when nil
  warn "Missing ENV['DATABASE_ADAPTER']."
else
  warn "Invalid ENV['DATABASE_ADAPTER']: #{ENV['DATABASE_ADAPTER']}."
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
  gem 'rubocop', '0.81.0'
  gem 'vcr'
  gem 'webmock'
end
