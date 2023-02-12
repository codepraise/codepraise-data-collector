# frozen_string_literal: true

require_relative '../init.rb'
require 'figaro'
require 'shoryuken'
require 'json'
require 'ostruct'
require 'logger'

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

    def self.logger
      log_file = File.open("logs.log", "a")
      Logger.new(log_file)
    end

    def self.redis
      CodePraise::Cache::Client.new(config)
    end

    Shoryuken.sqs_client = Aws::SQS::Client.new(
      access_key_id: config.AWS_ACCESS_KEY_ID,
      secret_access_key: config.AWS_SECRET_ACCESS_KEY,
      region: config.AWS_REGION
    )

    include Shoryuken::Worker
    # Shoryuken.sqs_client_receive_message_opts = { max_number_of_messages: 1 }

    shoryuken_options queue: config.CLONE_QUEUE_URL, auto_visibility_timeout: true, retry: 3
    # shoryuken_options queue: config.DEAD_LETTER_QUEUE_URL, auto_visibility_timeout: true

    def perform(sqs_msg, request)
      @gem = JSON.parse(request, object_class: OpenStruct)

      unless Worker.redis.get(@gem.repo_uri) || Worker.redis.exists_in_set?('done', @gem.repo_uri) || Worker.redis.exists_in_set?('not_found', @gem.repo_uri)
        Worker.redis.set(@gem.repo_uri, 'processing')
        Worker.logger.info("Processing #{@gem.repo_uri}")
        result = Service::CollectProjectInfo.new.call(gem: @gem)
        raise result.failure.message unless result.success?

        Worker.redis.add_to_set('done', @gem.repo_uri)
        Worker.redis.delete(@gem.repo_uri)
        Worker.logger.info("Done #{@gem.repo_uri}")
      end

      sqs_msg.delete
    rescue CodePraise::Github::Api::Response::Forbidden => e
      Worker.logger.error("Forbidden: #{request.to_s}\n Message: #{e.message}")

      Worker.redis.delete(@gem.repo_uri)
      if e.message.include?'You have exceeded a secondary rate limit.'
        sqs_msg.change_visibility(visibility_timeout: 60)
      elsif e.message.include?'API rate limit exceeded'
        sqs_msg.change_visibility(visibility_timeout: 7500)

        unless Worker.redis.get('sleep')
          Shoryuken.logger.info('Sleeping for 2 hours')
          Worker.redis.set('sleep', 'true')
          sleep 7200
          Worker.redis.delete('sleep')
        end
      end
    rescue CodePraise::Github::Api::Response::NotFound => e
      Worker.logger.error("NotFound: #{request.to_s}\n Message: #{e.message}")

      Worker.redis.add_to_set('not_found', @gem.repo_uri)
      Worker.redis.delete(@gem.repo_uri)
      sqs_msg.delete
    rescue StandardError => e
      Worker.logger.error("Exception: #{request.to_s}\n Message: #{e.message}")

      Worker.redis.delete(@gem.repo_uri)
      sqs_msg.change_visibility(visibility_timeout: 0)
    end
  end
end
