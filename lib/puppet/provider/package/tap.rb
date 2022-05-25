require 'puppet/provider/package'

Puppet::Type.type(:package).provide(:tap, :parent => Puppet::Provider::Package) do
  desc 'Tap management using HomeBrew on OSX'

  confine :operatingsystem => :darwin

  has_feature :installable
  has_feature :uninstallable

  has_feature :install_options

  if (File.exist?('/usr/local/bin/brew')) then
    @brewbin = '/usr/local/bin/brew'
    true
  elsif (File.exist?('/opt/homebrew/bin/brew')) then
    @brewbin = '/opt/homebrew/bin/brew'
  end

  commands :brew => @brewbin
  commands :stat => '/usr/bin/stat'

  def self.execute(cmd, failonfail = false, combine = false)
    owner = stat('-nf', '%Uu', "#{@brewbin}").to_i
    group = stat('-nf', '%Ug', "#{@brewbin}").to_i
    home  = Etc.getpwuid(owner).dir

    if owner == 0
      raise Puppet::ExecutionFailure, 'Homebrew does not support installations owned by the "root" user. Please check the permissions of /usr/local/bin/brew'
    end

    # the uid and gid can only be set if running as root
    if Process.uid == 0
      uid = owner
      gid = group
    else
      uid = nil
      gid = nil
    end

    if Puppet.features.bundled_environment?
      Bundler.with_clean_env do
        super(cmd, :uid => uid, :gid => gid, :combine => combine,
              :custom_environment => { 'HOME' => home }, :failonfail => failonfail)
      end
    else
      super(cmd, :uid => uid, :gid => gid, :combine => combine,
            :custom_environment => { 'HOME' => home }, :failonfail => failonfail)
    end
  end

  def execute(*args)
    # This does not return exit codes in puppet <3.4.0
    # See https://projects.puppetlabs.com/issues/2538
    self.class.execute(*args)
  end

  def install_options
    Array(resource[:install_options]).flatten.compact
  end

  def install
    resource_name = @resource[:name].downcase

    begin
      Puppet.debug "Tapping #{resource_name}"
      execute([command(:brew), :tap, resource_name, *install_options], :failonfail => true)
    rescue Puppet::ExecutionFailure => detail
      raise Puppet::Error, "Could not tap resource: #{detail}"
    end
  end

  def uninstall
    resource_name = @resource[:name].downcase

    begin
      Puppet.debug "Untapping #{resource_name}"
      execute([command(:brew), :untap, resource_name], :failonfail => true)
    rescue Puppet::ExecutionFailure => detail
      raise Puppet::Error, "Could not untap resource: #{detail}"
    end
  end

  def query
    resource_name = @resource[:name].downcase

    begin
      Puppet.debug "Querying tap #{resource_name}"
      output = execute([command(:brew), :tap])
      output.each_line do |line|
        line.chomp!
        next unless [resource_name, resource_name.gsub('homebrew-', '')].include?(line.downcase)

        return { :name => line, :ensure => 'present', :provider => 'tap' }
      end
    rescue Puppet::ExecutionFailure => detail
      Puppet.Err "Could not query tap: #{detail}"
    end

    nil
  end

  def self.instances
    taps = []

    begin
      Puppet.debug "Listing currently tapped repositories"
      output = execute([command(:brew), :tap])
      output.each_line do |line|
        line.chomp!
        next if line.empty?

        taps << new({ :name => line, :ensure => 'present', :provider => 'tap' })
      end
      taps
    rescue Puppet::ExecutionFailure => detail
      Puppet.Err "Could not list taps: #{detail}"
      nil
    end
  end
end
