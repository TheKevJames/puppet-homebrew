# Fact: has_arm64
#
# Purpose: check if arm64 is present
#
# Resolution:
#   Tests for presence of arm64, returns boolean
#   No value set if not on Darwin
#
# Caveats:
#   none
#
# Notes:
#   None

Facter.add(:has_arm64) do
  confine :operatingsystem => 'Darwin'
  setcode do
    system('arch -arm64 true >/dev/null 2>&1')
  end
end
