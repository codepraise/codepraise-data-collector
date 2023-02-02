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
        issues = @gateway.git_repo_issues(owner_name, project_name)
        build_entity(data, issues)
      end

      def build_entity(data, issues)
        DataMapper.new(data, issues, @token, @gateway_class).build_entity
      end

      # Extracts entity specific elements from data structure
      class DataMapper
        def initialize(data, issues, token, gateway_class)
          @data = data
          @issues = count_issues(issues)
          @member_mapper = MemberMapper.new(
            token, gateway_class
          )
        end

        def count_issues(issues)
          @issue_count = 0
          @pull_count = 0
          issues.each do |issue|
            if issue['node_id'].include? 'PR_'
              @pull_count += 1
            else
              @issue_count += 1
            end
          end
          [@issue_count, @pull_count]
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
            project_start: project_start,
            project_last_maintain: project_last_maintain,
            issues: @issues[0],
            pulls: @issues[1],
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

        def project_start
          DateTime.parse(@data['created_at'])
        end

        def project_last_maintain
          DateTime.parse(@data['updated_at'])
        end

        def downloads
          return 0 if Gems.search(name).empty?

          Gems.total_downloads(name)[:total_downloads]
        end
      end
    end
  end
end
