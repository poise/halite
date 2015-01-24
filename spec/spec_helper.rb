require 'rspec'
require 'rspec/its'
require 'simplecov'

# If we have a token, use codeclimate
if ENV['CODECLIMATE_REPO_TOKEN']
  require 'codeclimate-test-reporter'
  SimpleCov.formatter = CodeClimate::TestReporter::Formatter
end

SimpleCov.start do
  # Don't get coverage on the test cases themselves
  add_filter '/test/'
end

require 'halite'

RSpec.configure do |config|
  # Basic configuraiton
  config.run_all_when_everything_filtered = true
  config.filter_run(:focus)

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'
end
