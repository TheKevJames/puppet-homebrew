# Fact: is_arm64
#
# Purpose: check if we are running under arm64 architecture
#
# Resolution:
#   Executes `arch -arm64 true` and returns boolean result
#   No value set if not on Darwin

Facter.add(:is_arm64) do
  confine kernel: 'Darwin'

  setcode do
    system('arch -arm64 true >/dev/null 2>&1')
  end
end
