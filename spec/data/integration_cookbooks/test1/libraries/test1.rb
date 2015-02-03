ENV['HALITE_LOAD'] = 'test1'; begin; module Test1
end
ensure; ENV.delete('HALITE_LOAD'); end
