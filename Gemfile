source 'https://rubygems.org/'

gemspec

# Test fixture gems
group :development, :test do
  Dir[File.expand_path('../spec/data/gems/*', __FILE__)].each do |path|
    gem File.basename(path), path: path
  end
  gem 'berkshelf'
  gem 'chefspec'
end

group :travis do
  gem 'codeclimate-test-reporter'
end
