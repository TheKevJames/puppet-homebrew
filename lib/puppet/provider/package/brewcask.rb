require 'puppet/provider/package'
require_relative 'homebrew_provider'

Puppet::Type.type(:package).provide(:brewcask, parent: HomebrewProvider) do
  desc 'Package management using HomeBrew casks on OSX'

  confine operatingsystem: :darwin

  has_feature :installable
  has_feature :uninstallable
  has_feature :upgradeable
  has_feature :versionable
  has_feature :install_options

  def self.instances
    package_list.map { |hash| new(hash) }
  end

  def latest
    package = self.class.package_list(resource_name)
    package[:ensure]
  end

  def query
    self.class.package_list(resource_name)
  end

  def install
    Puppet.debug("Looking for #{install_name} package...")
    brew(:info, '--cask', install_name)

    Puppet.debug('Package found, installing...')
    output = brew(:install, '--cask', install_name, *install_options)

    return unless output.match?(/sha256 checksum/)

    Puppet.debug('Fixing checksum error...')
    mismatched = output.match(/Already downloaded: (.*)/).captures
    fix_checksum(mismatched)
  rescue Puppet::ExecutionFailure => detail
    raise Puppet::Error, "Could not install package: #{detail}"
  end

  def uninstall
    Puppet.debug("Uninstalling #{resource_name}")
    brew(:uninstall, '--cask', resource_name)
  rescue Puppet::ExecutionFailure => detail
    raise Puppet::Error, "Could not uninstall package: #{detail}"
  end

  def update
    Puppet.debug("Updating #{resource_name}")
    install
  end

  def self.package_list(*args)
    if args.empty?
      result = brew(:list, '--cask', '--versions', combine: false)
    else
      result = brew(:list, '--cask', '--versions', *args, failonfail: false, combine: false)
      Puppet.debug("Package #{args[0]} not installed") if result.empty?
      Puppet.debug("Found package #{result}") unless result.empty?
    end

    list = result.lines.map { |line| name_version_split(line) }
    args.empty? ? list : list.shift
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
