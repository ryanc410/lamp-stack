# lamp-stack
> Bash script to configure a LAMP stack on an Ubuntu or Debian based server.

---

## Table of Contents
* [General Info]()
* [Features]()
* [Setup]()
* [Issues]()
* [Contact]()

# General Information
This script was written in BASH and intended for use on an Ubuntu or Debian server. It installs all the necessary programs for a LAMP stack and uses PHP version 7.4.

# Features
-Apache Web Server (Packages: apache2 apache2-utils)
-PHP7.4 (Packages: readline,opcache,json,common,cli,mysql,fpm) libapache2-mod-php7.4)
-Mariadb Database Server

Script enables all programs to start automatically on boot. Apache Listens on Port 80 and Mariadb Listens on Port 3306.

Allows the user to set a custom Database root user password by passing the -p | --password option followed by the password to be set.
`./lamp-stack.sh --password SOMEPASSWORD | ./lamp-stack.sh -p SOMEPASSWORD`

Configures a virtual host file for your domain if the -v | --vhost option is passed during execution.
`./lamp-stack --vhost | ./lamp-stack -v`

# Setup

Clone the repository
````bash
git clone https://github.com/ryanc410/lamp-stack.git
````

CD into the new directory
````bash
cd lamp-stack
````

Make the script executable
````bash
chmod +x lamp-stack.sh
````

Execute the script
````bash
./lamp-stack.sh [OPTIONS] [ARGS]
