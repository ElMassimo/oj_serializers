eval File.read('Gemfile').sub('gemspec', 'gemspec ".."')

gem 'rails', '~> 7.0.3'
