Puppet::Type.type(:package).provide(:tap,
                                    :parent => :brewcommon,
                                    :source => :brewcommon) do
  desc 'Tap management using HomeBrew on OS X'

  def install
    name = @resource[:name]
    Puppet.debug "Tapping #{name}"
    output = execute([command(:brew), :tap, name, *install_options])

    if output =~ /Error: Invalid tap name/
      raise Puppet::Error, "Could not find tap #{name}"
    end
  end

  def uninstall
    name = @resource[:name]
    Puppet.debug "Untapping #{name}"
    execute([command(:brew), :untap, name])
  end

  def update
    raise Puppet::Error, "Can not re-tap #{@resource[:name]}"
  end

  def query
    name = @resource[:name]
    Puppet.debug "Querying tap #{name}"
    begin
      output = execute([command(:brew), :tap])
      output.each_line do |line|
        line.chomp!
        return { :name => line, :ensure => 'present', :provider => 'tap' } if line == name
      end
    rescue Puppet::ExecutionFailure => detail
      Puppet.Err "Could not query tap: #{detail}"
    end
    nil
  end

  def self.instances
    Puppet.debug "Listing currently tapped repositories"
    taps = []
    begin
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
