# frozen_string_literal: true

require_relative 'member_mapper.rb'
require 'rubygems'
require 'gems'

module CodePraise
  module Github
    # Data Mapper: Github repo -> Project entity
    class ProjectMapper
      def initialize(gh_token, gateway_class = Github::Api)
        @token = gh_token
        @gateway_class = gateway_class
        @gateway = @gateway_class.new(@token)
      end

      def find(owner_name, project_name)
        data = @gateway.git_repo_data(owner_name, project_name)
        build_entity(data)
      end

      def search(query, order)
        results = @gateway.git_repo_search(query, order)
        puts "Found #{results.count} projects"

        projects = results.reject do |proj|
          puts "Checking #{proj['name']}"
          begin
            Gems.total_downloads(proj['name']).empty?
            false
          rescue
            true
          end
        end

        puts "Found #{projects.count} actual ruby gem projects"
        projects.map do |proj|
          puts "Processing #{proj['name']}"
          build_entity(proj)
        end
      end

      def build_entity(data)
        DataMapper.new(data, @token, @gateway_class).build_entity
      end

      # Extracts entity specific elements from data structure
      class DataMapper
        def initialize(data, token, gateway_class)
          @data = data
          @member_mapper = MemberMapper.new(
            token, gateway_class
          )
          @issue_mapper = IssueMapper.new(
            token, gateway_class
          )
        end

        def build_entity
          CodePraise::Entity::Project.new(
            id: nil,
            origin_id: origin_id,
            name: name,
            size: size,
            ssh_url: ssh_url,
            http_url: http_url,
            owner: owner,
            contributors: contributors,
            issues: issues,
            project_start: project_start,
            project_last_maintain: project_last_maintain,
            downloads: downloads
          )
        end

        def origin_id
          @data['id']
        end

        def name
          @data['name']
        end

        def size
          @data['size']
        end

        def owner
          MemberMapper.build_entity(@data['owner'])
        end

        def http_url
          @data['html_url']
        end

        def ssh_url
          @data['git_url']
        end

        def contributors
          @member_mapper.load_several(@data['contributors_url'])
        end

        def issues
          owner_name, project_name = @data['full_name'].split('/')
          @issue_mapper.load_several(owner_name, project_name)
        end

        def project_start
          @data['created_at']
        end

        def project_last_maintain
          @data['updated_at']
        end

        def downloads
          Gems.total_downloads(name)[:total_downloads]
        end
      end
    end
  end
end
