require 'puppet/provider/package'
require 'puppet/provider/package/homebrew_provider'

Puppet::Type.type(:package).provide(:brew, parent: HomebrewProvider) do
  desc 'Package management using HomeBrew on OSX'

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
    brew(:info, install_name)

    Puppet.debug('Package found, installing...')
    output = brew(:install, install_name, *install_options)

    return unless output.match?(/sha256 checksum/)

    Puppet.debug('Fixing checksum error...')
    mismatched = output.match(/Already downloaded: (.*)/).captures
    fix_checksum(mismatched)
  rescue Puppet::ExecutionFailure => detail
    raise Puppet::Error, "Could not install package: #{detail}"
  end

  def uninstall
    Puppet.debug("Uninstalling #{resource_name}")
    brew(:uninstall, resource_name)
  rescue Puppet::ExecutionFailure => detail
    raise Puppet::Error, "Could not uninstall package: #{detail}"
  end

  def update
    Puppet.debug("Upgrading #{resource_name}")
    brew(:upgrade, resource_name)
  rescue Puppet::ExecutionFailure => detail
    raise Puppet::Error, "Could not upgrade package: #{detail}"
  end

  def self.package_list(*args)
    # Be fail-soft if we're looking for a specific package, but fail hard if we're listing all of them (if that errors,
    # something is wrong with Homebrew):
    cmd_output = brew(:list, '--versions', *args, failonfail: args.size == 0, combine: false)

    re_excludes = Regexp.union([
      /^==>.*/,
      /^Tapped \d+ formulae.*/
    ])
    lines = cmd_output.lines.delete_if { |line| line.match(re_excludes) }

    if args.size > 0
      if lines.empty?
        Puppet.debug("Package #{args[0]} not installed")
        return nil
      end

      Puppet.warning("Multiple matches for package #{args[0]} (#{lines.map(&:strip).join(', ')}) - using first one found") if lines.length > 1
      line = lines.shift
      Puppet.debug("Found package #{line}")
      return name_version_split(line)
    end

    lines.map { |line| name_version_split(line) }
  rescue Puppet::ExecutionFailure => detail
    raise Puppet::Error, "Could not list packages: #{detail}"
  end

  def self.name_version_split(line)
    match = line.match(/^(\S+)\s+(.+)/)
    if match
      {
        name: match[1],
        ensure: match[2],
        provider: :brew
      }
    else
      Puppet.warning("Could not match #{line}")
      nil
    end
  end
end
