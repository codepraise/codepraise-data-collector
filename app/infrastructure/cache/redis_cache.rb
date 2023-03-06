# frozen_string_literal: true

require 'redis'

module CodePraise
  module Cache
    # Redis client utility
    class Client
      def initialize(config)
        @redis = Redis.new(url: config.REDISCLOUD_URL)
      end

      def keys
        @redis.keys
      end

      def get(key)
        @redis.get(key)
      end

      def set(key, value)
        @redis.set(key, value)
      end

      def delete(key)
        @redis.del(key)
      end

      def add_to_set(key, value)
        @redis.sadd?(key, value)
      end

      def exists_in_set?(key, value)
        @redis.sismember(key, value)
      end

      def get_set(key)
        @redis.smembers(key)
      end

      def wipe
        keys.each { |key| @redis.del(key) }
      end

      def quit
        @redis.quit
      end
    end
  end
end
