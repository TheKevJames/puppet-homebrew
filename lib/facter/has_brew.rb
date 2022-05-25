# Fact: has_brew
#
# Purpose: check if brew is installed
#
# Resolution:
#   Tests for presence of brew, returns boolean
#   No value set if not on Darwin
#
# Caveats:
#   none
#
# Notes:
#   None

Facter.add(:has_brew) do
  confine :operatingsystem => 'Darwin'
  setcode do
    File.exists?('/usr/local/bin/brew') or File.exists?('/opt/homebrew/bin/brew') or system('brew --version >/dev/null 2>&1')
  end
end
