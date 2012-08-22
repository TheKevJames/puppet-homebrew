Facter.add(:has_compiler) do
  confine :operatingsystem => :darwin
  setcode do
    macosx_version = Facter.value('macosx_productversion_major').to_f
    compiler = (macosx_version < 10.7 && '/usr/bin/cc') || '/usr/bin/xcrun'
    File.exists?(compiler)
  end
end
