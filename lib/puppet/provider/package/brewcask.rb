require 'puppet/provider/package'
require 'puppet/provider/package/homebrew_common'

Puppet::Type.type(:package).provide(:brewcask, parent: Puppet::Provider::Package) do
  desc 'Package management using HomeBrew casks on OSX'

  confine operatingsystem: :darwin

  include Puppet::Provider::Package::HomebrewCommon

  has_feature :installable
  has_feature :uninstallable
  has_feature :upgradeable
  has_feature :versionable
  has_feature :install_options

  commands brew: brewbin
  commands stat: '/usr/bin/stat'

  def self.instances
    package_list.map { |hash| new(hash) }
  end

  def latest
    package = self.class.package_list(justme: resource_name)
    package[:ensure]
  end

  def query
    self.class.package_list(justme: resource_name)
  end

  def install
    Puppet.debug("Looking for #{install_name} package...")
    execute([command(:brew), :info, '--cask', install_name], failonfail: true)

    Puppet.debug('Package found, installing...')
    output = execute([command(:brew), :install, '--cask', install_name, *install_options], failonfail: true)

    return unless output.match?(/sha256 checksum/)

    Puppet.debug('Fixing checksum error...')
    mismatched = output.match(/Already downloaded: (.*)/).captures
    fix_checksum(mismatched)
  rescue Puppet::ExecutionFailure => detail
    raise Puppet::Error, "Could not install package: #{detail}"
  end

  def uninstall
    Puppet.debug("Uninstalling #{resource_name}")
    execute([command(:brew), :uninstall, '--cask', resource_name], failonfail: true)
  rescue Puppet::ExecutionFailure => detail
    raise Puppet::Error, "Could not uninstall package: #{detail}"
  end

  def update
    Puppet.debug("Updating #{resource_name}")
    install
  end

  def self.package_list(options = {})
    Puppet.debug('Listing installed packages')

    if options[:justme]
      result = execute([command(:brew), :list, '--cask', '--versions', options[:justme]])
      Puppet.debug("Package #{options[:justme]} not installed") if result.empty?
      Puppet.debug("Found package #{result}") unless result.empty?
    else
      result = execute([command(:brew), :list, '--cask', '--versions'])
    end

    list = result.lines.map { |line| name_version_split(line) }
    options[:justme] ? list.shift : list
  rescue Puppet::ExecutionFailure => detail
    raise Puppet::Error, "Could not list packages: #{detail}"
  end

  def self.name_version_split(line)
    match = line.match(/^(\S+)\s+(.+)/)
    if match
      {
        name: match[1],
        ensure: match[2],
        provider: :brewcask
      }
    else
      Puppet.warning("Could not match #{line}")
      nil
    end
  end
end
