# frozen_string_literal: true

require 'http'
require 'logger'

module CodePraise
  module Github
    # Library for Github Web API
    class Api
      def initialize(token)
        @gh_token = token
      end

      def logger
        log_file = File.open("github_logs.log", "a")
        Logger.new(log_file)
      end

      def git_repo_data(username, project_name)
        Request.new(@gh_token).repo(username, project_name).parse
      end

      def git_repo_contributors(username, project_name)
        Request.new(@gh_token).contributors(username, project_name).parse
      end

      def contributors_data(contributors_url)
        request = Request.new(@gh_token).get(contributors_url)
        result = request.parse

        if request['Link']
          last_page = page_count(request)
          (2..last_page).each do |page|
            result += Request.new(@gh_token).get(contributors_url + "?page=#{page}").parse
          end

          # promises = (2..last_page).map do |page|
          #   Concurrent::Promise.execute(executor: :io) do
          #     result_for_page = Request.new(@gh_token).get(contributors_url + "?page=#{page}").parse
          #     # logger.info("result_for_page: #{result_for_page}")
          #     result.concat(result_for_page.to_a)
          #   end
          # end
          #
          # # Wait for all the promises to complete
          # Concurrent::Promise.zip(*promises).wait!
        end

        result
      end

      def git_repo_commits(username, project_name)
        Request.new(@gh_token).commits(username, project_name).parse
      end

      def git_repo_issues(username, project_name)
        request = Request.new(@gh_token).issues(username, project_name, '?state=all&direction=asc&per_page=100')
        result = request.parse

        if request['Link']
          last_page = page_count(request)
          (2..last_page).each do |page|
            result += Request.new(@gh_token).issues(username, project_name, "?state=all&direction=asc&per_page=100&page=#{page}").parse
          end

          # promises = (2..last_page).map do |page|
          #   Concurrent::Promise.execute(executor: :io) do
          #     result_for_page = Request.new(@gh_token).issues(username, project_name, "?state=all&direction=asc&per_page=100&page=#{page}").parse
          #     # logger.info("result_for_page: #{result_for_page}")
          #     result.concat(result_for_page.to_a)
          #   end
          # end
          #
          # # Wait for all the promises to complete
          # Concurrent::Promise.zip(*promises).wait!
        end

        result
      end

      def git_repo_search(query, order)
        request = Request.new(@gh_token).search(query, order)
        result = request.parse['items']

        if request['Link']
          last_page = page_count(request)
          (2..last_page).each do |page|
            result += Request.new(@gh_token).search(query + "&page=#{page}", order).parse['items']
          end

          # promises = (2..last_page).map do |page|
          #   Concurrent::Promise.execute(executor: :io) do
          #     result_for_page = Request.new(@gh_token).search(query + "&page=#{page}", order).parse['items']
          #     # logger.info("result_for_page: #{result_for_page}")
          #     result.concat(result_for_page.to_a)
          #   end
          # end
          #
          # # Wait for all the promises to complete
          # Concurrent::Promise.zip(*promises).wait!
        end

        result
      end

      def page_count(request)
        page_urls = request['Link'].scan(/<(https?:\/\/\S+)>/)
        page_urls.last.first.match(/[&|?]page=(\d+)/)[1].to_i
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

        def search(query, order)
          # "https://api.github.com/search/repositories?q=language:ruby+topic:rubygems&per_page=3&sort=updated"
          get(ENDPOINT + "search/repositories?q=#{query}&per_page=100&sort=updated&order=#{order}")
        end

        def get(url)
          http_response = HTTP.headers(
            'Accept' => 'application/vnd.github.v3+json',
            'Authorization' => "token #{@token}"
          ).get(url)

          Response.new(http_response).tap do |response|
            raise response.error, response.parse['message'] unless response.successful?
            raise Response::Redirect, response['Location'] if response.code == 301
          end
        rescue Response::Redirect => e
          url = e.message
          get(url)
        end

        def logger
          log_file = File.open("github_logs.log", "a")
          Logger.new(log_file)
        end
      end

      # Decorates HTTP responses from Github with success/error
      class Response < SimpleDelegator
        Unauthorized = Class.new(StandardError)
        NotFound = Class.new(StandardError)
        Redirect = Class.new(StandardError)
        Forbidden = Class.new(StandardError)

        HTTP_ERROR = {
          401 => Unauthorized,
          403 => Forbidden,
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
