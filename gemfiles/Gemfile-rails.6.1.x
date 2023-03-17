eval File.read('Gemfile').sub('gemspec', 'gemspec ".."')

gem 'rails', '~> 6.1.0'
