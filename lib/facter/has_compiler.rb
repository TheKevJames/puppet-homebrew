Facter.add(:has_compiler) do
  confine :operatingsystem => :darwin
  setcode do
    File.exists?('/usr/bin/cc') || system('/usr/bin/xcrun -find cc >/dev/null 2>&1')
  end
end
