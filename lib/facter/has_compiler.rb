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
  confine kernel: 'Darwin'

  setcode do
    has_xcode = File.exist?('/Applications/Xcode.app') ||
      File.exist?('/Library/Developer/CommandLineTools/')
    has_cc = File.exist?('/usr/bin/cc') ||
      system('/usr/bin/xcrun -find cc >/dev/null 2>&1')

    has_xcode && has_cc
  end
end
