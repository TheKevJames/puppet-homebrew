# Fact: has_brew
#
# Purpose: check if brew is installed
#
# Resolution:
#   Tests for presence of brew, returns boolean
#   No value set if not on Darwin

Facter.add(:has_brew) do
  confine kernel: 'Darwin'

  setcode do
    File.exist?('/usr/local/bin/brew') ||
      File.exist?('/opt/homebrew/bin/brew') ||
      system('command -v brew >/dev/null 2>&1')
  end
end
