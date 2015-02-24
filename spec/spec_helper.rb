require 'rspec'
require 'rspec/its'
require 'simplecov'

# Check for coverage stuffs
formatters = []
if ENV['CODECLIMATE_REPO_TOKEN']
  require 'codeclimate-test-reporter'
  formatters << CodeClimate::TestReporter::Formatter
end

if ENV['CODECOV_TOKEN']
  require 'codecov'
  formatters << SimpleCov::Formatter::Codecov
end

unless formatters.empty?
  SimpleCov.formatters = formatters
end

SimpleCov.start do
  # Don't get coverage on the test cases themselves.
  add_filter '/spec/'
  add_filter '/test/'
  # Codecov doesn't automatically ignore vendored files.
  add_filter '/vendor/'
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
