# frozen_string_literal: true

require 'dry/transaction'

module CodePraise
  module Service
    # Transaction to store project from Github API to database
    class CollectGems
      include Dry::Transaction

      step :search_gem
      step :store_gem

      private

      DB_ERR_MSG = 'Having trouble accessing the database'
      RUBYGEMS_NOT_FOUND_MSG = 'Having trouble accessing the rubygems API'

      def search_gem(input)
        puts "Getting gems from Rubygems..."

        input[:gems] = []
        per_page = 30 # fixed by rubygems
        pages = (input[:amount].to_f / per_page).ceil
        (1..pages).each do |page|
          input[:gems] += gems_from_rubygems(input[:query], page)
        end

        Success(input)
      rescue StandardError => e
        puts e.full_message
        Failure(Value::Result.new(status: :not_found, message: e.to_s))
      end

      def store_gem(input)
        redis = CodePraise::Cache::Client.new(App.config)
        gems = input[:gems].each do |gem|
          puts "Storing #{gem.name} in database..."
          if gem_in_database(gem)
            Repository::For.entity(gem).update(gem)
          else
            Repository::For.entity(gem).create(gem)
          end

          next if !gem.valid || redis.exists_in_set?('done', gem.repo_uri) || redis.exists_in_set?('not_found', gem.repo_uri)

          clone_queues = [App.config.CLONE_QUEUE_URL]
          notify_workers(gem, clone_queues)
        end

        Success(Value::Result.new(status: :stored, message: nil))
      rescue StandardError => e
        puts e.backtrace.join("\n")
        Failure(Value::Result.new(status: :internal_error, message: DB_ERR_MSG))
      end

      # following are support methods that other services could use

      def gems_from_rubygems(query, page)
        Rubygems::GemMapper
          .new
          .search(query, page)
      rescue StandardError => e
        puts e.full_message
        raise GH_NOT_FOUND_MSG
      end

      def gem_in_database(gem)
        Repository::For.klass(Entity::Gem)
          .find_name(gem.name)
      end

      def notify_workers(data, queues)
        puts "Notifying workers to clone #{data.name}..."
        queues.each do |queue_url|
          Messaging::Queue.new(queue_url, App.config)
                          .send(data.to_attr_hash.to_json)
        end
      end
    end
  end
end
