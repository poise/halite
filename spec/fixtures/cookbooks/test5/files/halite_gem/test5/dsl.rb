require 'test2/version'

module Test5
  module DSL
    def test5_method
      "!!!!!!!!!!test5#{Test2::VERSION}"
    end
  end
end

class Chef
  class Recipe
    include Test5::DSL
  end
end
