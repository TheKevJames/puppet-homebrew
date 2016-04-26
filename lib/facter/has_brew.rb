Facter.add(:has_brew) do
  setcode do
    "nil"
  end
end

Facter.add(:has_brew) do
  confine :operatingsystem => :darwin
  setcode do
    File.exists?('/usr/local/bin/brew') or system('brew --version >/dev/null 2>&1') ? "true" : "false"
  end
end
