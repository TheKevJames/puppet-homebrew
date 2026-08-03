require 'puppet/provider/package'
require 'puppet/provider/package/homebrew_provider'

Puppet::Type.type(:package).provide(:homebrew, parent: HomebrewProvider) do
  desc 'Package management using HomeBrew (+ casks!) on OSX'

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
    begin
      Puppet.debug("Looking for #{install_name} package on brew...")
      brew(:info, install_name)

      Puppet.debug('Package found, installing...')
      output = brew(:install, install_name, *install_options)

      return unless output.match?(/sha256 checksum/)

      Puppet.debug('Fixing checksum error...')
      mismatched = output.match(/Already downloaded: (.*)/).captures
      fix_checksum(mismatched)
    rescue Puppet::ExecutionFailure
      Puppet.debug("Package #{install_name} not found on Brew. Trying BrewCask...")
      install_cask
    end
  rescue Puppet::ExecutionFailure => detail
    raise Puppet::Error, "Could not install package: #{detail}"
  end

  def install_cask
    brew(:info, '--cask', install_name)

    Puppet.debug('Package found on brewcask, installing...')
    output = brew(:install, '--cask', install_name, *install_options)

    return unless output.match?(/sha256 checksum/)

    Puppet.debug('Fixing checksum error...')
    mismatched = output.match(/Already downloaded: (.*)/).captures
    fix_checksum(mismatched)
  end

  def uninstall
    Puppet.debug("Uninstalling #{resource_name}")
    brew(:uninstall, resource_name)
  rescue Puppet::ExecutionFailure
    brew(:uninstall, '--cask', resource_name)
  rescue Puppet::ExecutionFailure => detail
    raise Puppet::Error, "Could not uninstall package: #{detail}"
  end

  def update
    Puppet.debug("Updating #{resource_name}")
    install
  end

  def self.package_list(*args)
    # TODO we should eagerly fetch cask and formula versions and error if a requested package occurs more than once.
    # Be fail-soft if we're looking for a specific package, but fail hard if we're listing all of them (if that errors,
    # something is wrong with Homebrew):
    result = brew(:list, '--versions', *args, failonfail: args.size == 0, combine: false)
    if args.size > 0
      unless result.include?(args[0])
        result += brew(:list, '--cask', '--versions', *args, failonfail: false, combine: false)
      end
      Puppet.debug("Package #{args[0]} not installed") if result.empty?
      Puppet.debug("Found package #{result}") unless result.empty?
    else
      result += brew(:list, '--cask', '--versions', combine: false)
    end

    list = result.lines.map { |line| name_version_split(line) }
    args.size > 0 ? list.shift : list
  rescue Puppet::ExecutionFailure => detail
    raise Puppet::Error, "Could not list packages: #{detail}"
  end

  def self.name_version_split(line)
    match = line.match(/^(\S+)\s+(.+)/)
    if match
      {
        name: match[1],
        ensure: match[2],
        provider: :homebrew
      }
    else
      Puppet.warning("Could not match #{line}")
      nil
    end
  end
end
