require 'puppet/provider/package'
require 'puppet/provider/package/homebrew_common'

Puppet::Type.type(:package).provide(:brew, parent: Puppet::Provider::Package) do
  desc 'Package management using HomeBrew on OSX'

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
    execute([command(:brew), :info, install_name], failonfail: true)

    Puppet.debug('Package found, installing...')
    output = execute([command(:brew), :install, install_name, *install_options], failonfail: true)

    return unless output.match?(/sha256 checksum/)

    Puppet.debug('Fixing checksum error...')
    mismatched = output.match(/Already downloaded: (.*)/).captures
    fix_checksum(mismatched)
  rescue Puppet::ExecutionFailure => detail
    raise Puppet::Error, "Could not install package: #{detail}"
  end

  def uninstall
    Puppet.debug("Uninstalling #{resource_name}")
    execute([command(:brew), :uninstall, resource_name], failonfail: true)
  rescue Puppet::ExecutionFailure => detail
    raise Puppet::Error, "Could not uninstall package: #{detail}"
  end

  def update
    Puppet.debug("Upgrading #{resource_name}")
    execute([command(:brew), :upgrade, resource_name], failonfail: true)
  rescue Puppet::ExecutionFailure => detail
    raise Puppet::Error, "Could not upgrade package: #{detail}"
  end

  def self.package_list(options = {})
    Puppet.debug('Listing installed packages')

    cmd_line = [command(:brew), :list, '--versions']
    cmd_line << options[:justme] if options[:justme]

    cmd_output = execute(cmd_line)

    re_excludes = Regexp.union([
      /^==>.*/,
      /^Tapped \d+ formulae.*/
    ])
    lines = cmd_output.lines.delete_if { |line| line.match(re_excludes) }

    if options[:justme]
      if lines.empty?
        Puppet.debug("Package #{options[:justme]} not installed")
        return nil
      end

      Puppet.warning("Multiple matches for package #{options[:justme]} - using first one found") if lines.length > 1
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
