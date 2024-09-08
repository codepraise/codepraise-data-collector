# frozen_string_literal: true

require 'gems'

module CodePraise
  module Rubygems
    # Library for Github Web API
    class Api
      def search(query = '*', page = 2)
        Gems.search(query, {page:})
      end
    end
  end
end
