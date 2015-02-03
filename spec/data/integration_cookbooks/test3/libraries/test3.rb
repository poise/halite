ENV['HALITE_LOAD'] = 'test3'; begin; require_relative 'test3__dsl'

module Test3
end
ensure; ENV.delete('HALITE_LOAD'); end
