# frozen_string_literal: true

folders = %w[rubygems github messaging database]
folders.each do |folder|
  require_relative "#{folder}/init.rb"
end
