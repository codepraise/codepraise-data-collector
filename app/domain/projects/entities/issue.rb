# frozen_string_literal: true

require 'dry-types'
require 'dry-struct'

module CodePraise
  module Entity
    # Domain entity for any coding projects
    class Issue < Dry::Struct
      include Dry.Types

      attribute :id,            Integer.optional
      attribute :origin_id,     Strict::Integer
      attribute :node_id,       Strict::String
      attribute :url,           Strict::String
      attribute :title,         Strict::String
      attribute :number,        Strict::Integer
      attribute :type,          Strict::String

      def to_attr_hash
        to_hash.reject { |key, _| %i[id].include? key }
      end
    end
  end
end
