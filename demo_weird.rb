require './require_app'
require 'git'
require_app
require 'pathname'
require 'pry'
binding.pry

# created in 2012 but from git log the first commit happend in 2024
user_name = "trailblazer"
project_name = "cells-haml"

# created in 2011 but the first commit happend in 2004s
user_name = "monora"
project_name = "stream"
response = CodePraise::Github::Api.new(CodePraise::App.config.GITHUB_TOKEN).git_repo_data(user_name, project_name)
response['created_at']
folder_name = "#{user_name}_#{project_name}"
repo_path = "/Users/twohorse/Desktop/repostore_temp/#{folder_name}"
g = Git.open(repo_path)
all_commits = g.log
all_commits.first.date
all_commits.last.date