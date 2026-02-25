require 'puppet/provider/package'
require 'puppet/provider/package/homebrew_common'

Puppet::Type.type(:package).provide(:tap, parent: Puppet::Provider::Package) do
  desc 'Tap management using HomeBrew on OSX'

  confine operatingsystem: :darwin

  include Puppet::Provider::Package::HomebrewCommon

  has_feature :installable
  has_feature :uninstallable
  has_feature :install_options

  commands brew: brewbin
  commands stat: '/usr/bin/stat'

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
    Puppet.debug("Querying tap #{resource_name}")
    output = execute([command(:brew), :tap])
    output.each_line do |line|
      line = line.chomp
      next unless [resource_name, resource_name.gsub('homebrew-', '')].include?(line.downcase)

      return { name: line, ensure: 'present', provider: 'tap' }
    end
  rescue Puppet::ExecutionFailure => detail
    Puppet.err("Could not query tap: #{detail}")

    nil
  end

  def self.instances
    taps = []

    Puppet.debug('Listing currently tapped repositories')
    output = execute([command(:brew), :tap])
    output.each_line do |line|
      line = line.chomp
      next if line.empty?

      taps << new({ name: line, ensure: 'present', provider: 'tap' })
    end
    taps
  rescue Puppet::ExecutionFailure => detail
    Puppet.err("Could not list taps: #{detail}")
    nil
  end
end
