# frozen_string_literal: true

folders = %w[rubygems github database]
folders.each do |folder|
  require_relative "#{folder}/init.rb"
end
