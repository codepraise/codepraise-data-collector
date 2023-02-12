# frozen_string_literal: true

require_relative 'member_mapper.rb'
require 'rubygems'
require 'gems'

module CodePraise
  module Rubygems
    # Data Mapper: Rubygems repo -> Gem entity
    class GemMapper
      def initialize(gateway_class = Rubygems::Api)
        @gateway_class = gateway_class
        @gateway = @gateway_class.new
      end

      def search(query, page)
        @gateway.search(query, page).map do |data|
          GemMapper.build_entity(data)
        end
      end

      def self.build_entity(data)
        DataMapper.new(data).build_entity
      end

      # Extracts entity specific elements from data structure
      class DataMapper
        def initialize(data)
          @data = data
        end

        def build_entity
          Entity::Gem.new(
            id: nil,
            name: name,
            downloads: downloads,
            source_code_uri: source_code_uri,
            homepage_uri: homepage_uri,
            repo_uri: repo_uri
          )
        end

        private

        def name
          @data['name']
        end

        def downloads
          @data['downloads']
        end

        def source_code_uri
          @data['source_code_uri'] || ''
        end

        def homepage_uri
          @data['homepage_uri'] || ''
        end

        def repo_uri
          uri = if source_code_uri.include?('github.com')
            source_code_uri[/https?:\/\/github.com\/[\w-]+\/[\w-]+/]
          elsif homepage_uri.include?('github.com')
            homepage_uri[/https?:\/\/github.com\/[\w-]+\/[\w-]+/]
          end
          return '' if uri.nil?

          uri.start_with?('https') ? uri: uri.sub('http', 'https')
        end
      end
    end
  end
end
