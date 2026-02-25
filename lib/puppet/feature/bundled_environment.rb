require 'puppet/util/feature'

Puppet.features.add(:bundled_environment) do
  next false unless defined?(Bundler)

  Bundler.respond_to?(:with_unbundled_env) || Bundler.respond_to?(:with_clean_env)
end
