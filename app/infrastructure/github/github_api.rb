# frozen_string_literal: true

require 'http'

module CodePraise
  module Github
    # Library for Github Web API
    class Api
      def initialize(token)
        @gh_token = token
      end

      def git_repo_data(username, project_name)
        Request.new(@gh_token).repo(username, project_name).parse
      end

      def git_repo_contributors(username, project_name)
        Request.new(@gh_token).contributors(username, project_name).parse
      end

      def contributors_data(contributors_url)
        Request.new(@gh_token).get(contributors_url).parse
      end

      def git_repo_commits(username, project_name)
        Request.new(@gh_token).commits(username, project_name).parse
      end

      def git_repo_issues(username, project_name)
        request = Request.new(@gh_token).issues(username, project_name, '?state=all')
        result = request.parse

        page_urls = request['Link'].scan(/<(https?:\/\/[\S]+)>/)

        last_page = page_urls.last.first.match(/page=(\d+)/)[1].to_i
        (2..last_page).each do |page|
          puts "page: #{page}"
          result += Request.new(@gh_token).issues(username, project_name, "?state=all&page=#{page}").parse
        end
        
        result
      end

      # Sends out HTTP requests to Github
      class Request
        ENDPOINT = 'https://api.github.com/'

        def initialize(token)
          @token = token
        end

        def repo(username, project_name)
          get(ENDPOINT + 'repos/' + [username, project_name].join('/'))
        end

        def commits(username, project_name)
          get(ENDPOINT + 'repos/' + [username, project_name].join('/') + '/commits')
        end

        def contributors(username, project_name)
          get(ENDPOINT + 'repos/' + [username, project_name].join('/') + '/contributors')
        end

        def issues(username, project_name, arguments = '')
          get(ENDPOINT + 'repos/' + [username, project_name].join('/') + '/issues' + arguments)
        end

        def get(url)
          http_response = HTTP.headers(
            'Accept' => 'application/vnd.github.v3+json',
            'Authorization' => "token #{@token}"
          ).get(url)

          Response.new(http_response).tap do |response|
            raise(response.error) unless response.successful?
          end
        end
      end

      # Decorates HTTP responses from Github with success/error
      class Response < SimpleDelegator
        Unauthorized = Class.new(StandardError)
        NotFound = Class.new(StandardError)

        HTTP_ERROR = {
          401 => Unauthorized,
          404 => NotFound
        }.freeze

        def successful?
          HTTP_ERROR.key?(code) ? false : true
        end

        def error
          HTTP_ERROR[code]
        end
      end
    end
  end
end
