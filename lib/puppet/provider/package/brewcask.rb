require 'puppet/provider/package'
require 'puppet_x/homebrew/brew_command'

Puppet::Type.type(:package).provide(:brewcask, :parent => Puppet::Provider::Package) do
  desc 'Package management using HomeBrew casks on OSX'

  confine :operatingsystem => :darwin

  extend PuppetX::Homebrew::BrewCommand

  has_feature :installable
  has_feature :uninstallable
  has_feature :upgradeable
  has_feature :versionable
  has_feature :install_options

  @brewbin = detect_brew_bin
  commands :brew => @brewbin
  commands :stat => '/usr/bin/stat'

  def run_brew(*args, **opts)
    self.class.run_brew(*args, **opts)
  end

  def fix_checksum(files)
    begin
      for file in files
        File.delete(file)
      end
    rescue Errno::ENOENT
      Puppet.warning "Could not remove mismatched checksum files #{files}"
    end

    raise Puppet::ExecutionFailure, "Checksum error for package #{name} in files #{files}"
  end

  def resource_name
    if @resource[:name].match(/^https?:\/\//)
      @resource[:name]
    else
      @resource[:name].downcase
    end
  end

  def install_name
    should = @resource[:ensure].downcase

    case should
    when true, false, Symbol
      resource_name
    else
      "#{resource_name}@#{should}"
    end
  end

  def install_options
    Array(resource[:install_options]).flatten.compact
  end

  def self.instances
    package_list.collect { |hash| new(hash) }
  end

  # brew decides what is outdated. Otherwise -- or when from an untrusted
  # tap -- the installed value is returned, so Puppet sees no change.
  def latest
    entry = self.class.outdated_entry(resource_name)
    if entry.nil?
      Puppet.debug "#{resource_name} is up to date according to brew"
      return properties[:ensure]
    end

    if self.class.untrusted_tap?(entry['tap'])
      current = properties[:ensure]
      @resource.warning self.class.untrusted_tap_message(current, entry)
      return current
    end

    Puppet.debug "Latest version for #{resource_name}: #{entry['version']}"
    entry['version']
  rescue Puppet::ExecutionFailure => detail
    raise Puppet::Error, "Could not query latest version of package: #{detail}"
  end

  def self.prefetch(packages)
    forget_brew_state
    super
  end

  def self.outdated
    @outdated ||= outdated_casks
  end

  def self.outdated_entry(name)
    outdated_lookup(outdated, name)
  end

  def query
    self.class.package_list(:justme => resource_name)
  end

  def install
    begin
      Puppet.debug "Looking for #{install_name} package..."
      run_brew('info', '--cask', install_name)
    rescue Puppet::ExecutionFailure => detail
      raise Puppet::Error, "Could not find package: #{install_name}"
    end

    begin
      Puppet.debug "Package found, installing..."
      output = run_brew('install', '--cask', install_name, *install_options)

      if output =~ /sha256 checksum/
        Puppet.debug "Fixing checksum error..."
        mismatched = output.match(/Already downloaded: (.*)/).captures
        fix_checksum(mismatched)
      end
    rescue Puppet::ExecutionFailure => detail
      raise Puppet::Error, "Could not install package: #{detail}"
    end
  end

  def uninstall
    begin
      Puppet.debug "Uninstalling #{resource_name}"
      run_brew('uninstall', '--cask', resource_name)
    rescue Puppet::ExecutionFailure => detail
      raise Puppet::Error, "Could not uninstall package: #{detail}"
    end
  end

  def update
    if installed?
      Puppet.debug "Updating #{resource_name}"
      begin
        run_brew('info', '--cask', resource_name)
      rescue Puppet::ExecutionFailure => detail
        raise Puppet::Error, "Could not find package: #{install_name}"
      end

      begin
        Puppet.debug "Package found, upgrading..."
        output = run_brew('upgrade', '--cask', install_name, *install_options)

        if output =~ /sha256 checksum/
          Puppet.debug "Fixing checksum error..."
          mismatched = output.match(/Already downloaded: (.*)/).captures
          fix_checksum(mismatched)
        end
      rescue Puppet::ExecutionFailure => detail
        raise Puppet::Error, "Could not upgrade package: #{detail}"
      end
    else
      install
    end
  end

  def installed?
    is_not_installed = run_brew('info', '--cask', install_name).split("\n").grep(/^Not installed$/).first
    is_not_installed.nil?
  rescue Puppet::ExecutionFailure => detail
    raise Puppet::Error, "Could not get status of package: #{detail}"
  end

  def self.package_list(options={})
    Puppet.debug "Listing installed packages"
    begin
      # combine: false keeps brew's stderr out of the parse: merged in, those
      # lines become phantom packages or nil entries, and one nil entry fails
      # the whole prefetch with "No resource and no name in property hash".
      if resource_name = options[:justme]
        # failonfail: false -- a cask that isn't installed is the nominal case
        # for a first install or for `ensure => absent`, not an error.
        result = run_brew('list', '--cask', '--versions', resource_name,
                          failonfail: false, combine: false).to_s
        if result.empty?
          Puppet.debug "Package #{resource_name} not installed"
        else
          Puppet.debug "Found package #{result}"
        end
        list = result.lines.map { |line| name_version_split(line) }.compact
      else
        list = installed_list
      end
    rescue Puppet::ExecutionFailure => detail
      raise Puppet::Error, "Could not list packages: #{detail}"
    end

    if options[:justme]
      return list.shift
    else
      return list
    end
  end

  # Full inventory. The JSON listing is preferred -- it does not abort with
  # "Cask <token> exists in multiple taps" the way the text one does as soon as
  # two taps ship the same token -- but it is not always available; see
  # brew_list_json in PuppetX::Homebrew::BrewCommand.
  def self.installed_list
    parsed = brew_list_json('--cask')
    if parsed
      return Array(parsed['casks']).map { |pkg| package_hash(pkg['token'], pkg['versions']) }.compact
    end

    Puppet.debug 'brew has no JSON listing (jq missing?), falling back to the text listing'
    run_brew('list', '--cask', '--versions', combine: false).to_s
      .lines.map { |line| name_version_split(line) }.compact
  end

  def self.package_hash(name, versions)
    return nil if name.nil? || name.empty?

    # Truncated like name_version_split. `latest` returns it unchanged.
    version = Array(versions).first.to_s[/\A[.\d]+/]
    return nil if version.nil?

    {
      :name     => name,
      :ensure   => version,
      :provider => :brewcask
    }
  end

  def self.name_version_split(line)
    return nil if line.strip.empty?

    if line =~ (/^(\S+)\s+([.\d]+)/)
      {
        :name     => $1,
        :ensure   => $2,
        :provider => :brewcask
      }
    else
      Puppet.warning "Could not match #{line}"
      nil
    end
  end
end
