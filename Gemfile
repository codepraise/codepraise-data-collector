# frozen_string_literal: true

source 'https://rubygems.org'
ruby File.read('.ruby-version').strip

# CONFIGURATION
gem 'figaro', '~> 1.2'
gem 'rake', '~> 13.0'

# Network
gem 'http', '~> 5'

# APPLICATION LAYER
# Service
gem 'dry-monads', '~> 1.4'
gem 'dry-transaction', '~> 0.13'
gem 'dry-validation', '~> 1.7'

# DOMAIN LAYER
# Validation
gem 'dry-struct', '~> 1'
gem 'dry-types', '~> 1'

gem 'gems'

# INFRASTRUCTURE LAYER
# Database
gem 'sequel', '~> 5.49'

group :development, :test do
  gem 'sqlite3', '~> 1.4'
end