if ENV['HALITE_LOAD']; module Test3
  module DSL
    def test3_method
      '!!!!!!!!!!test3'
    end
  end
end

class Chef
  class Recipe
    include Test3::DSL
  end
end
end
