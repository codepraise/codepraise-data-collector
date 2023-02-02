# frozen_string_literal: true

require 'figaro'
require 'sequel'

module CodePraise
  # Environment-specific configuration
  class App
    Figaro.application = Figaro::Application.new(
      environment: ENV['RACK_ENV'] || 'development',
      path: File.expand_path('config/secrets.yml')
    )
    Figaro.load

    def self.config
      Figaro.env
    end

    def self.environment
      ENV['RACK_ENV'] || 'development'
    end

    ENV['DATABASE_URL'] = "sqlite://#{config.DB_FILENAME}"
    def self.DB
      Sequel.connect(ENV.fetch('DATABASE_URL'))
    end
  end
end