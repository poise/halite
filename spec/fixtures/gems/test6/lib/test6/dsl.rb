require 'test2/version'

module Test6
  module DSL
    def test6_method
      "!!!!!!!!!!test6#{Test2::VERSION}"
    end
  end
end

class Chef
  class Recipe
    include Test6::DSL
  end
end
