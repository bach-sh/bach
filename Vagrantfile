# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "chaifeng/ubuntu-20.04-docker-20.10.17#{(`uname -m`.strip == "arm64")?"-arm64":""}"

  for bash_version in ["4.3", "4.4", "5.0", "5.2", "devel"] do
    config.vm.provision "Test on Ubuntu", type: "shell", inline: <<-SHELL
      set -euo pipefail
      echo exit 1 | /vagrant/run-tests.sh
    SHELL
    config.vm.provision "Test on Bash-#{bash_version}", type: "shell", inline: <<-SHELL
      set -euo pipefail
      bash_version="#{bash_version}"
      if [[ "$bash_version" == devel ]]; then docker pull bash:"$bash_version"; fi
      docker run --rm -v /vagrant:/src \
                 --name "test-bach-on-bash-${bash_version}" \
                 bash:"$bash_version" /src/run-tests.sh
    SHELL
  end
  config.vm.provision "Test Done", type: "shell", inline: <<-SHELL
    echo ======================
    echo Yes, all tests passed.
    echo ======================
  SHELL
end
