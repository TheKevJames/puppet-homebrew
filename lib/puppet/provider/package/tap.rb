require 'etc'
require 'puppet/provider/package'

Puppet::Type.type(:package).provide(:tap, parent: Puppet::Provider::Package) do
  desc 'Tap management using HomeBrew on OSX'

  confine operatingsystem: :darwin

  has_feature :installable
  has_feature :uninstallable
  has_feature :install_options

  def self.brewbin
    @brewbin ||= ['/opt/homebrew/bin/brew', '/usr/local/bin/brew'].find { |path| File.exist?(path) }
  end

  commands brew: brewbin
  commands stat: '/usr/bin/stat'

  def self.with_unbundled_env
    return yield unless Puppet.features.bundled_environment?

    if Bundler.respond_to?(:with_unbundled_env)
      Bundler.with_unbundled_env { yield }
    else
      Bundler.with_clean_env { yield }
    end
  end

  def self.execute(cmd, failonfail = false, combine = false)
    owner = stat('-nf', '%Uu', brewbin).to_i
    group = stat('-nf', '%Ug', brewbin).to_i
    home = Etc.getpwuid(owner).dir

    if owner.zero?
      raise Puppet::ExecutionFailure,
            'Homebrew does not support installations owned by the "root" user. Please check the permissions of /usr/local/bin/brew'
    end

    uid, gid = if Process.uid.zero?
                 [owner, group]
               else
                 [nil, nil]
               end

    with_unbundled_env do
      super(cmd,
            uid: uid,
            gid: gid,
            combine: combine,
            custom_environment: { 'HOME' => home },
            failonfail: failonfail)
    end
  end

  def execute(*args)
    self.class.execute(*args)
  end

  def install_options
    Array(resource[:install_options]).flatten.compact
  end

  def install
    resource_name = resource[:name].downcase
    Puppet.debug("Tapping #{resource_name}")
    execute([command(:brew), :tap, resource_name, *install_options], failonfail: true)
  rescue Puppet::ExecutionFailure => detail
    raise Puppet::Error, "Could not tap resource: #{detail}"
  end

  def uninstall
    resource_name = resource[:name].downcase
    Puppet.debug("Untapping #{resource_name}")
    execute([command(:brew), :untap, resource_name], failonfail: true)
  rescue Puppet::ExecutionFailure => detail
    raise Puppet::Error, "Could not untap resource: #{detail}"
  end

  def query
    resource_name = resource[:name].downcase

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
