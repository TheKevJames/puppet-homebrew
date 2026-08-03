require 'puppet/provider/package'
require 'puppet/provider/package/homebrew_common'

Puppet::Type.type(:package).provide(:tap, parent: HomebrewProvider) do
  desc 'Tap management using HomeBrew on OSX'

  confine operatingsystem: :darwin

  has_feature :installable
  has_feature :uninstallable
  has_feature :install_options

  commands brew: brew_binary_config[:path]

  def install
    Puppet.debug("Tapping #{resource_name}")
    execute([command(:brew), :tap, resource_name, *install_options], failonfail: true)
  rescue Puppet::ExecutionFailure => detail
    raise Puppet::Error, "Could not tap resource: #{detail}"
  end

  def uninstall
    Puppet.debug("Untapping #{resource_name}")
    execute([command(:brew), :untap, resource_name], failonfail: true)
  rescue Puppet::ExecutionFailure => detail
    raise Puppet::Error, "Could not untap resource: #{detail}"
  end

  def query
    # Homebrew does (or did in supported older versions) alias tap names with a 'homebrew-' prefix, such that
    # commands like 'brew tap foo/bar' would result 'brew tap' reporting *either* 'foo/bar' or 'foo/homebrew-bar'.
    # This provider supports the same semantics:
    self.class.instances.each do |inst|
      normalized = inst.name.gsub(/^([^\/]+)\/(?:homebrew-)?(.+)/, "\1/\2")
      return inst.properties if [inst.name, normalized].include?(resource_name)
    end
    nil
  end

  def self.instances
    taps = []

    Puppet.debug('Listing currently tapped repositories')
    output = execute([command(:brew), :tap])
    output.each_line do |line|
      line = line.chomp
      next if line.empty?
      Puppet.debug("Found tap #{line}")
      taps << new({ name: line, ensure: 'present', provider: 'tap' })
    end
    taps
  rescue Puppet::ExecutionFailure => detail
    Puppet.err("Could not list taps: #{detail}")
    nil
  end
end
