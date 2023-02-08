# frozen_string_literal: true

require 'sequel'

module CodePraise
  module Database
    # Object-Relational Mapper for Issues
    class GemOrm < Sequel::Model(:gems)

      plugin :timestamps, update_on_create: true

      def self.find_or_create(gem_info)
        first(name: gem_info[:name]) || create(gem_info)
      end
    end
  end
end
