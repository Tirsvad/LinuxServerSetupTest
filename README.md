# LinuxServerSetupScript

## Script for setting up a complete server system
Debian or compatible distribution

## Features
* Option add Ajenti control panel
* Option add NGINX webserver
  * Default use SSL certificate (letsencrypt)
* Create a privileged user
  * option add ssh-key
  * option set shell (default /bin/bash)
* sshd
  * option ssh-key for passwordless connection
  * option disable root login
* Firewall
  * Automatic configure based on choices made
* Setting hostname
* Update system software

### Installation
Get it and run it

```
wget --no-check-certificate https://api.github.com/repos/TirsvadCMS/LinuxServerSetup/tarball/master
tar xpvf master -C "LinuxServerSetup" --strip-components=1
cd LinuxServerSetup
bash setup/start.sh
```

### TODO
1. Optional Sql server
  * Postgresql
2. Optional webserver
  * django
  * uwsgi
3. Optional e-mail server
  * spam filter
  * anti virus
  * easy add email via web tool

### Development
Want to contribute? Great!
Find us [here](https://github.com/TirsvadCMS/LinuxServerSetup/)