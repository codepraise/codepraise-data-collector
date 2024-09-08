require './require_app'
require 'git'
require_app
require 'pathname'
require 'pry'
binding.pry

def count_directories(path)
  # 确保路径是一个文件夹
  raise "#{path} is not a directory" unless File.directory?(path)

  # 使用Dir.glob与File.directory?来计数
  Dir.glob(File.join(path, '*/')).count do |folder|
    File.directory?(folder)
  end
end

# 指定需要检查的文件夹路径
folder_path = "/Volumes/未命名/repostore_temp"
puts "There are #{count_directories(folder_path)} directories in #{folder_path}"


count = 0

CodePraise::Database::GemOrm.all[0..].each do |gem|
    p "-----第#{count}個-----"
    if gem.repo_uri == '' || !gem.repo_uri.include?('github')
      p "gem: #{gem.name} 無法從 github 下載"
      count += 1
      next
    end
    uri = URI(gem.repo_uri)
    repo_path = uri.path[1..-1] # Remove leading slash
    username, project_name = repo_path.split('/')
    clone_path = "/Volumes/未命名/repostore_temp/#{username}_#{project_name}"
    
    # 检查目标路径是否已存在
    if File.exist?(clone_path)
      p "gem: #{gem.name} 目標位置已存在，跳過"
      count += 1
      next
    end
    
    begin
        response = CodePraise::Github::Api.new(CodePraise::App.config.GITHUB_TOKEN).git_repo_data(username, project_name)
        create_year = Date.parse(response['created_at']).year
        if create_year <= 2014
          p "gem: #{gem.name} 開始下載"
          Git.clone("https://github.com/#{username}/#{project_name}.git", clone_path)
          p "gem: #{gem.name} 下載完成"
        else
          p "gem: #{gem.name} 不夠年輕，跳過"
        end
      rescue CodePraise::Github::Api::Response::NotFound, Git::GitExecuteError
        p "gem: 找不到#{gem.name} 這個 gem，跳過"
        count += 1
        next
    end
      count += 1
  end
  

g.branches.each do |branch|
    puts branch.name
    # branch_commits = g.log(branch.name)
    # branch_commits.each do |commit|
    #     all_commits.push(commit.date)
    # end
end               