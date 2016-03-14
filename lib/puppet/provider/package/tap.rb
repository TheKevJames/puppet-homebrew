require 'puppet/provider/package'

Puppet::Type.type(:package).provide(:tap, :parent => Puppet::Provider::Package) do
  TAP_CUSTOM_ENVIRONMENT = { "HOMEBREW_CACHE" => "/Library/Caches/Homebrew", "HOMEBREW_LOGS" => "/Library/Logs/Homebrew/" }
  desc "Homebrew repository management on OS X"

  confine  :operatingsystem => :darwin

  has_feature :installable, :install_options
  has_feature :uninstallable

  commands :id   => "/usr/bin/id"
  commands :stat => "/usr/bin/stat"
  commands :sudo => "/usr/bin/sudo"
  commands :brew => "/usr/local/bin/brew"

  def self.execute(cmd)
    owner = super([command(:stat), '-nf', '%Uu', command(:brew)]).to_i
    environment = TAP_CUSTOM_ENVIRONMENT.merge('HOME' => Etc.getpwuid(owner).dir)
    Puppet.debug "command owner is: #{owner}, home: #{environment['HOME']}"
    if super([command(:id), '-u']).to_i.zero?
      Puppet.debug "running command in sudo environment as current user is root"
      Dir.chdir(environment['HOME']) do
        super(cmd, :uid => owner, :failonfail => true, :combine => true, :custom_environment => environment)
      end
    else
      Puppet.debug "running command with current (non-root) user"
      super(cmd, :failonfail => true, :combine => true, :custom_environment => environment)
    end
  end

  def execute(*args)
    self.class.execute(*args)
  end

  # Install packages, known as formulas, using brew.
  def install
    Puppet.notice "Tapping repository #{@resource[:name]}"
    output = execute([command(:brew), :tap, @resource[:name]])

    # Fail hard if there is no tap available.
    if output =~ /Error: Invalid tap name/
      raise Puppet::ExecutionFailure, "Could not find package #{@resource[:name]}"
    end
  end

  def uninstall
    Puppet.notice "Untapping repository #{@resource[:name]}"
    execute([command(:brew), :untap, @resource[:name]])
  end

  def query
    Puppet.debug "Querying tap #{@resource[:name]}"
    begin
      output = execute([command(:brew), :tap])
      output.each_line do |line|
        line.chomp!
        return { :name => line, :ensure => 'present', :provider => 'tap' } if line == @resource[:name]
      end
    rescue Puppet::ExecutionFailure
      Puppet.err "Instances failed: #{$!}"
    end
    nil
  end

  def self.instances
    Puppet.debug "Listing currently tapped repositories"
    taps = []
    begin
      process = execute([command(:brew), :tap])
      process.each_line do |line|
        line.chomp!
        next if line.empty?
        Puppet.debug "  Repository #{line} is currently tapped."
        taps << new({ :name => line, :ensure => 'present', :provider => 'tap' })
      end
      taps
    rescue Puppet::ExecutionFailure
      Puppet.err "Instances failed: #{$!}"
      nil
    end
  end
end
