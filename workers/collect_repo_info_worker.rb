# frozen_string_literal: true

require_relative '../init.rb'
require 'figaro'
require 'shoryuken'
require 'json'
require 'ostruct'

MUTEX = Mutex.new

module CodePraise
  # Shoryuken worker class to clone repos in parallel
  class Worker
    Figaro.application = Figaro::Application.new(
      environment: ENV['RACK_ENV'] || 'development',
      path: File.expand_path('config/secrets.yml')
    )
    Figaro.load

    def self.config
      Figaro.env
    end

    # binding.irb

    Shoryuken.sqs_client = Aws::SQS::Client.new(
      access_key_id: config.AWS_ACCESS_KEY_ID,
      secret_access_key: config.AWS_SECRET_ACCESS_KEY,
      region: config.AWS_REGION
    )

    include Shoryuken::Worker
    # Shoryuken.sqs_client_receive_message_opts = { max_number_of_messages: 1 }

    shoryuken_options queue: config.CLONE_QUEUE_URL, auto_visibility_timeout: true

    def perform(sqs_msg, request)
      gem = JSON.parse(request, object_class: OpenStruct)
      result = Service::CollectProjectInfo.new.call(gem: gem)
      result.success? ? sqs_msg.delete : raise(result.failure)
    rescue StandardError => e
      puts e.full_message
      sqs_msg.delete
    end
  end
end
