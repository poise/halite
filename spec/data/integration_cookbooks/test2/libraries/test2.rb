ENV['HALITE_LOAD'] = '1'; begin; require_relative 'test2__resource'

module Test2
end
ensure; ENV.delete('HALITE_LOAD'); end
