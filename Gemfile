source 'http://rubygems.org'

# syck removed from ruby 2, safe_yaml updated to fix this eventually, puppet~>3 uses older safe_yaml
gem 'safe_yaml', '>= 1.0.4'

gem 'facter', '>= 1.7.0'
gem 'metadata-json-lint', '>= 0.0.11'
gem 'puppet', ENV.key?('PUPPET_VERSION') ? "#{ENV['PUPPET_VERSION']}" : ['>= 3.3']
gem 'puppet-lint', '>= 1.1.0'

# missing facter dependency
gem 'CFPropertyList', '~> 2.3.3'
