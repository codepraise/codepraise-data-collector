# frozen_string_literal: true

folders = %w[cache codepraise-api rubygems github messaging database]
folders.each do |folder|
  require_relative "#{folder}/init.rb"
end
