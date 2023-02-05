# frozen_string_literal: true

require_relative 'member.rb'
require_relative 'issue.rb'
require 'dry-types'
require 'dry-struct'

module CodePraise
  module Entity
    # Domain entity for any coding projects
    class Project < Dry::Struct
      include Dry.Types

      attribute :id,            Integer.optional
      attribute :origin_id,     Strict::Integer
      attribute :name,          Strict::String
      attribute :size,          Strict::Integer
      attribute :ssh_url,       Strict::String
      attribute :http_url,      Strict::String
      attribute :owner,         Member
      attribute :contributors,  Strict::Array.of(Member)
      attribute :issues,        Strict::Array.of(Issue)
      attribute :project_start, Strict::String
      attribute :project_last_maintain, Strict::String
      attribute :downloads,     Strict::Integer

      def fullname
        "#{owner.username}/#{name}"
      end

      def to_attr_hash
        to_hash.reject { |key, _| %i[id owner contributors issues].include? key }
      end
    end
  end
end
