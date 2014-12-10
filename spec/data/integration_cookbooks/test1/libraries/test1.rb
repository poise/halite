ENV['HALITE_LOAD'] = '1'; begin; module Test1
end
ensure; ENV.delete('HALITE_LOAD'); end
