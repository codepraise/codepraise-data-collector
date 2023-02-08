# frozen_string_literal: true

require 'dry-types'
require 'dry-struct'

module CodePraise
  module Entity
    # Domain entity for any coding projects
    class Gem < Dry::Struct
      include Dry.Types

      attribute :id,            Integer.optional
      attribute :name,          Strict::String
      attribute :source_code_uri,  Strict::String
      attribute :homepage_uri,  Strict::String
      attribute :repo_uri,      Strict::String
      attribute :downloads,     Strict::Integer

      def to_attr_hash
        to_hash.reject { |key, _| %i[id].include? key }
      end
    end
  end
end
