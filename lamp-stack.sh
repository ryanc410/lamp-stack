 #!/usr/bin/env bash
###############################################
# AUTHOR: Ryan C
# DATE: 03/09/2022
# https://github.com/ryanc410
###############################################
# VARIABLES
###############################################
domain=$(hostname -f)
exit_stat=$?
###############################################
# FUNCTIONS
###############################################
function enable()
{
    systemctl enable $1
    systemctl start $1
}
function install_vhost()
{
  cat >> /etc/apache2/sites-available/"$domain".conf <<-VHOST
<VirtualHost *:80>
  ServerName $domain
  ServerAlias www.$domain

  DocumentRoot /var/www/html

  ErrorLog /var/log/apache2/$domain-error.log
  CustomLog /var/log/apache2/$domain-access.log combined
</VirtualHost>
VHOST

a2ensite "$domain".conf

a2dissite 000-default.conf

systemctl restart apache2
}
function show_usage()
{
    clear
    echo "###################################"
    echo "# LAMP STACK INSTALLER SCRIPT"
    echo "###################################"
    echo ""
    echo "USAGE: $0 [OPTIONS..]"
    echo ""
    echo "OPTIONS"
    echo "-h | --help                      Shows this usage screen."
    echo "-p | --password [ARG..]          Requires an argument which will be the database Admin User's password."
    echo "-v | --vhost                     Tells the script to generate a virtual host file after installing Apache."
    echo ""
    echo "This script installs a LAMP stack with a basic configuration."
    echo ""
    echo "To set a custom Mariadb Root User password you must execute the script with the -p | --password option with"
    echo "the password as an argument. If the password option is not passed, a default random 32 character password"
    echo "is generated using openssl and printed in the post-install text file."
    echo ""
    echo "The script by default does not generate a virtual host file for your domain. You must pass the -v | --vhost option"
    echo "in order for the script to generate a Virtual Host file for you."
    echo ""
    echo "Comments, Issues or concerns can be addressed on Github at https://github.com/ryanc410/lamp-stack"
}
###############################################
# SCRIPT
###############################################
while [ "$1" != "" ]; do
    case $1 in
        -h | --help )      show_usage
                           exit 0
                           ;;
        -p | --password )  if [[ -z $2 ]]; then
                             echo "This option requires an argument.."
                             sleep 3
                             show_usage
                             exit 1
                           else
                             dbroot_password=$2
                             shift 2
                           fi
                           ;;
        -v | --vhost )     VHOST=true
                           shift
                           ;;
        * )                show_usage
                           exit 1
                           ;;
    esac
  shift
done

if [[ $EUID != 0 ]]; then
    echo "This script needs to be ran as root or with sudo."
    sleep 3
    exit 1
fi

if [[ -z $dbroot_password ]]; then
  dbroot_password=$(openssl rand -base64 32)
  cat >> post_install.txt <<-CREDS
DATABASE ROOT USER CREDENTIALS
------------------------------------------------
DATABASE ROOT USER PASSWORD: $dbroot_password
------------------------------------------------
RECOMMENDATIONS
------------------------------------------------
-Configure php.ini files at /etc/php/7.4/apache2/php.ini
                            /etc/php/7.4/fpm/php.ini
                            /etc/php/7.4/cli/php.ini
-Secure Apache with SSL using easy auto-ssl.sh script.
https://github.com/ryanc410/auto-ssl.git
CREDS
chmod 600 credentials.txt &>/dev/null
fi

echo "Updating Server.."
apt update  &>/dev/null
apt upgrade -y &>/dev/null

echo "Installing Apache Web Server.."
apt install apache2 apache2-utils -y &>/dev/null
enable apache2 &>/dev/null

netstat -anp | grep apache | grep 80 &>/dev/null
if [[ $exit_stat != 0 ]]; then
    echo "The Apache Web Server could not be installed.."
    sleep 3
    exit 1
else
    echo "The Apache Web Server has been successfully installed and is listening on Port 80.."
    sleep 3
fi

echo "Setting Web Root Directory Permissions.."
chown www-data:www-data /var/www/html/ -R &>/dev/null

echo "Creating servername.conf file.."
echo "ServerName localhost">>/etc/apache2/conf-available/servername.conf &>/dev/null
a2enconf servername.conf &>/dev/null

if [[ $VHOST = true ]]; then
    install_vhost
fi

echo "Restarting Apache Web Server.."
systemctl reload apache2 &>/dev/null

echo "Installing Mariadb Server.."
apt install mariadb-server mariadb-client -y &>/dev/null

enable mariadb &>/dev/null

netstat -anp | grep mysql | grep 3306 &>/dev/null
if [[ $exit_stat != 0 ]]; then
  echo "Mariadb Installation failed.."
  sleep 3
  exit 1
else
  echo "Mariadb was successfully installed and is Listening on port 3306.."
  sleep 3
fi

echo "Running mysql_secure_installation.."
mysql -u root <<SECURE_INSTALLATION
SET PASSWORD FOR root@localhost = PASSWORD('$dbroot_password');
FLUSH PRIVILEGES;
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DELETE FROM mysql.db WHERE Db='test' OR Db='test_%';
FLUSH PRIVILEGES;
SECURE_INSTALLATION

echo "Installing PHP version 7.4 and required modules.."
apt install php7.4 libapache2-mod-php7.4  php-common  php7.4-{readline,opcache,json,common,cli,mysql,fpm} -y &>/dev/null

echo "Enabling php7.4-fpm in Apache.."
a2dismod php7.4 &>/dev/null

a2enmod proxy_fcgi setenvif &>/dev/null

a2enconf php7.4-fpm &>/dev/null

enable php7.4-fpm

systemctl restart apache2 &>/dev/null

echo "Restarting Apache Web Server.."
systemctl restart apache2 &>/dev/null

echo "LAMP Stack configuration complete."
sleep 3
echo "Check Post-installation notes in post_install.txt.."
sleep 3
exit 0
