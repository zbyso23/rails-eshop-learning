
### Remove Rbenv
```bash
rm -rf "$(rbenv root)"
```

### Install RVM
```bash
sudo apt-get update
sudo apt-get install -y curl g++ gcc make autoconf automake bison libgdbm-dev libncurses5-dev libsqlite3-dev libtool libyaml-dev pkg-config sqlite3 zlib1g-dev libgmp-dev libreadline-dev libssl-dev libffi-dev

gpg --keyserver keyserver.ubuntu.com --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB

curl -sSL https://get.rvm.io | bash -s stable
source ~/.rvm/scripts/rvm

rvm --version
```

### Install Ruby in RVM
```bash
rvm install 3.3.7
rvm --default use 3.3.7
```


### Uninstall Rails
```
gem uninstall rails -v 7.0.0
gem uninstall railties -v 7.0.0
gem uninstall rackup -v 7.0.0
```

