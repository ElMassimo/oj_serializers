def main_gemfile
  File.read('Gemfile').sub('gemspec', 'gemspec path: ".."')
end
