# Fact: has_compiler
#
# Purpose: check if Xcode Command Line Tools is installed
#
# Resolution:
#   Tests for presence of cc, returns boolean
#   No value set if not on Darwin
#
# Caveats:
#   none
#
# Notes:
#   None

Facter.add(:has_compiler) do
  confine :operatingsystem => 'Darwin'
  setcode do
    File.exists?('/usr/bin/cc') or system('/usr/bin/xcrun -find cc >/dev/null 2>&1')
  end
end

Facter.add(:has_compiler) do
  # /usr/bin/cc exists in Mavericks, but it's not real
  confine :operatingsystem => 'Darwin', :macosx_productversion_major => '10.9'
  setcode do
    (File.exists?('/Applications/Xcode.app') or File.exists?('/Library/Developer/CommandLineTools/')) and
        (File.exists?('/usr/bin/cc') or system('/usr/bin/xcrun -find cc >/dev/null 2>&1'))
  end
end
