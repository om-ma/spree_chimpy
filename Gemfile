source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

gem 'spree', '~> 4.5'
gem 'libnotify'
gem 'fuubar'
gem 'byebug'
gem 'pry-byebug'
gem 'rails-controller-testing'

gemspec
