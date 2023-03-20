# frozen_string_literal: true

def main_gemfile
  "ENV['NO_RAILS'] = 'true'\n#{File.read('Gemfile').sub('gemspec', 'gemspec path: ".."')}"
end
