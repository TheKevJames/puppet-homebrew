require 'puppet/provider/package'
require 'puppet_x/homebrew/brew_command'

Puppet::Type.type(:package).provide(:homebrew, :parent => Puppet::Provider::Package) do
  desc 'Package management using HomeBrew (+ casks!) on OSX'

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

  # brew decides what is outdated. Otherwise -- or when pinned or from an
  # untrusted tap -- the installed value is returned, so Puppet sees no change.
  def latest
    current = properties[:ensure]
    entry   = self.class.outdated_entry(resource_name)

    if entry.nil?
      Puppet.debug "#{resource_name} is up to date according to brew"
      current
    elsif entry['pinned']
      Puppet.debug "#{resource_name} is pinned, not upgrading it"
      current
    elsif self.class.untrusted_tap?(entry['tap'])
      @resource.warning self.class.untrusted_tap_message(current, entry)
      current
    else
      Puppet.debug "Latest version for #{resource_name}: #{entry['version']}"
      entry['version']
    end
  rescue Puppet::ExecutionFailure => detail
    raise Puppet::Error, "Could not query latest version of package: #{detail}"
  end

  def self.prefetch(packages)
    forget_brew_state
    super
  end

  def self.outdated
    @outdated ||= [outdated_formulae, outdated_casks]
  end

  # Formulae first, as brew resolves names.
  def self.outdated_entry(name)
    outdated.each do |list|
      entry = outdated_lookup(list, name)
      return entry if entry
    end
    nil
  end

  def query
    self.class.package_list(:justme => resource_name)
  end

  def install
    begin
      Puppet.debug "Package #{install_name} found, installing..."
      output = run_brew('install', install_name, *install_options)

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
      run_brew('uninstall', resource_name)
    rescue Puppet::ExecutionFailure => detail
      raise Puppet::Error, "Could not uninstall package: #{detail}"
    end
  end

  def update
    if installed?
      begin
        Puppet.debug "Package #{resource_name} found, upgrading..."
        output = run_brew('upgrade', install_name, *install_options)

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
    begin
      Puppet.debug "Check if #{resource_name} package installed"
      is_not_installed = run_brew('info', install_name).split("\n").grep(/^Not installed$/).first
    rescue Puppet::ExecutionFailure => detail
      raise Puppet::Error, "Could not get status of package: #{detail}"
    end
    is_not_installed.nil?
  end

  def self.package_list(options={})
    Puppet.debug "Listing installed packages"
    begin
      if resource_name = options[:justme]
        escaped = Regexp.escape(resource_name)
        # Targeted lookup, cheaper than a full inventory. failonfail: false --
        # brew exits non-zero for a package that simply isn't installed, the
        # nominal case for `ensure => absent` and for any first install.
        # `brew list --versions <name>` matches formulae only, hence the
        # cask-scoped retry, or an installed cask is never uninstalled.
        # combine: false keeps brew's stderr out of the parse (see text_listing).
        result = run_brew('list', '--versions', resource_name, failonfail: false, combine: false).to_s
        if result.empty?
          result = run_brew('list', '--versions', '--cask', resource_name, failonfail: false, combine: false).to_s
        end
        matched = result.lines.grep(/^#{escaped} /).first
        if matched.nil?
          Puppet.debug "Package #{resource_name} not installed"
          list = []
        else
          Puppet.debug "Found package #{resource_name}"
          Puppet.debug "Stored #{matched} in package_list"
          list = [name_version_split(matched)].compact
        end
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

  # Full inventory. The JSON listing is preferred but not always available;
  # see brew_list_json in PuppetX::Homebrew::BrewCommand.
  def self.installed_list
    parsed = brew_list_json
    return json_package_list(parsed) if parsed

    Puppet.debug 'brew has no JSON listing (jq missing?), falling back to the text listing'
    text_listing
  end

  def self.json_package_list(parsed)
    casks    = Array(parsed['casks']).map { |pkg| package_hash(pkg['token'], pkg['versions']) }
    formulae = Array(parsed['formulae']).map { |pkg| package_hash(pkg['name'], pkg['versions']) }

    (casks + formulae).compact
  end

  # Text listing fallback. combine: false is what keeps brew's stderr out of the
  # parse: merged in (Puppet's default), a tap deprecation notice turned into
  # phantom packages and nil entries, and one nil entry fails the prefetch of
  # every package in the catalog with "No resource and no name in property hash".
  def self.text_listing
    result = run_brew('list', '--versions', '--cask', combine: false).to_s
    result += run_brew('list', '--versions', '--formulae', combine: false).to_s

    result.lines.map { |line| name_version_split(line) }.compact
  end

  def self.package_hash(name, versions)
    return nil if name.nil? || name.empty?

    version = Array(versions).reject { |v| v.nil? || v.empty? }.join(' ')
    {
      :name     => name,
      # A cask with no recorded version is still installed: report it present
      # rather than dropping it, or Puppet reinstalls it on every run.
      :ensure   => version.empty? ? :present : version,
      :provider => :homebrew
    }
  end

  def self.name_version_split(line)
    return nil if line.strip.empty?

    if line =~ (/^(\S+)\s+(.+)/)
      {
        :name     => $1,
        :ensure   => $2,
        :provider => :homebrew
      }
    else
      Puppet.warning "Could not match #{line}"
      nil
    end
  end
end
