# frozen_string_literal: true

folders = %w[infrastructure domain application]
folders.each do |folder|
  require_relative "#{folder}/init.rb"
end
