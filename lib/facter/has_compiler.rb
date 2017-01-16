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
    # /usr/bin/cc exists in Mavericks, but it's not real
    if Gem::Version.new(Facter.value(:macosx_productversion_major)) >= Gem::Version.new('10.9')
      (File.exists?('/Applications/Xcode.app') or File.exists?('/Library/Developer/CommandLineTools/')) and
          (File.exists?('/usr/bin/cc') or system('/usr/bin/xcrun -find cc >/dev/null 2>&1'))
    else
      File.exists?('/usr/bin/cc') or system('/usr/bin/xcrun -find cc >/dev/null 2>&1')
    end
  end
end
