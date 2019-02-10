# LinuxServerSetup
## Description
This script aimed goal is to set up a complete web server environment.\
Optional LEMP / LAMP. Web application as optional.
### Requirement
Debain or Ubuntu fresh install
## Installation
Get it and run it
```
wget --no-check-certificate https://api.github.com/repos/TirsvadCMS/LinuxServerSetup/tarball/master
tar xpvf master -C "LinuxServerSetup" --strip-components=1
cd LinuxServerSetup
bash setup/start.sh
```
## Features
* Optional database Postgresql and Mysql
* Optional control panel Ajenti
* Optional webserver NGINX
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
### TODO
1. Optional web application
  * django
  * weblate
  * pgadmin
2. Optional e-mail server
  * spam filter
  * anti virus
  * easy add email via web tool
### Development
Want to contribute? Great!\
Find us [here](https://github.com/TirsvadCMS/LinuxServerSetup/)
