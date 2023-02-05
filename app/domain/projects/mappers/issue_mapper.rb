# frozen_string_literal: true

require_relative 'member_mapper.rb'
require 'rubygems'
require 'gems'

module CodePraise
  module Github
    # Data Mapper: Github repo -> Project entity
    class IssueMapper
      def initialize(gh_token, gateway_class = Github::Api)
        @token = gh_token
        @gateway_class = gateway_class
        @gateway = @gateway_class.new(@token)
      end

      def load_several(username, project_name)
        @gateway.git_repo_issues(username, project_name).map do |data|
          IssueMapper.build_entity(data)
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
          Entity::Issue.new(
            id: nil,
            origin_id: origin_id,
            node_id: node_id,
            url: url,
            title: title,
            number: number,
            type: type
          )
        end

        private

        def origin_id
          @data['id'].to_i
        end

        def node_id
          @data['node_id']
        end

        def url
          @data['url']
        end

        def title
          @data['title']
        end

        def number
          @data['number']
        end

        def type
          if @data['node_id'].include? 'PR_'
            'pull_request'
          else
            'issue'
          end
        end
      end
    end
  end
end
