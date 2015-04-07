require 'test2/version'

module Test3
  module DSL
    def test3_method
      "!!!!!!!!!!test3#{Test2::VERSION}"
    end
  end
end

class Chef
  class Recipe
    include Test3::DSL
  end
end
