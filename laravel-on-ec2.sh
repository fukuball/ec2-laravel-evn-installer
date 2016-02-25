#!/usr/bin/env bash

# Update Package List

apt-get update

# Remove Bug File

rm /boot/grub/menu.lst

# Update System Packages
apt-get -y upgrade

# Force Locale

echo "LC_ALL=en_US.UTF-8" >> /etc/default/locale
locale-gen en_US.UTF-8
update-locale LANG=en_US.UTF-8 LC_CTYPE=en_US.UTF-8 LC_ALL=en_US.UTF-8

# Install Some PPAs

apt-get install -y software-properties-common curl

apt-add-repository ppa:nginx/stable -y
apt-add-repository ppa:rwky/redis -y
apt-add-repository ppa:chris-lea/node.js -y
apt-add-repository ppa:ondrej/php5-5.6 -y

wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main" >> /etc/apt/sources.list.d/postgresql.list'

curl -s https://packagecloud.io/gpg.key | sudo apt-key add -
echo "deb http://packages.blackfire.io/debian any main" | sudo tee /etc/apt/sources.list.d/blackfire.list

# Update Package Lists

apt-get update

# Install Some Basic Packages

apt-get install -y build-essential dos2unix gcc git libmcrypt4 libpcre3-dev \
make python2.7-dev python-pip re2c supervisor unattended-upgrades whois vim

# Set My Timezone

ln -sf /usr/share/zoneinfo/UTC /etc/localtime

# Install PHP Stuffs

apt-get install -y php5-cli php5-dev php-pear \
php5-mysqlnd php5-pgsql php5-sqlite \
php5-apcu php5-json php5-curl php5-gd \
php5-gmp php5-imap php5-mcrypt php5-xdebug \
php5-memcached

# Make MCrypt Available

ln -s /etc/php5/conf.d/mcrypt.ini /etc/php5/mods-available
sudo php5enmod mcrypt

# Install Mailparse PECL Extension

pecl install mailparse
echo "extension=mailparse.so" > /etc/php5/mods-available/mailparse.ini
ln -s /etc/php5/mods-available/mailparse.ini /etc/php5/cli/conf.d/20-mailparse.ini


# Install Composer

curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

# Add Composer Global Bin To Path

printf "\nPATH=\"/home/ubuntu/.composer/vendor/bin:\$PATH\"\n" | tee -a /home/ubuntu/.profile

# Install Laravel Envoy

sudo su ubuntu <<'EOF'
/usr/local/bin/composer global require "laravel/envoy=~1.0"
EOF

# Set Some PHP CLI Settings

sudo sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php5/cli/php.ini
sudo sed -i "s/display_errors = .*/display_errors = On/" /etc/php5/cli/php.ini
sudo sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php5/cli/php.ini
sudo sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php5/cli/php.ini

# Install Nginx & PHP-FPM

apt-get install -y nginx php5-fpm

rm /etc/nginx/sites-enabled/default
rm /etc/nginx/sites-available/default
service nginx restart

# Add The HHVM Key & Repository

wget -O - http://dl.hhvm.com/conf/hhvm.gpg.key | apt-key add -
echo deb http://dl.hhvm.com/ubuntu utopic main | tee /etc/apt/sources.list.d/hhvm.list
apt-get update
apt-get install -y hhvm

# Configure HHVM To Run As Homestead

service hhvm stop
sed -i 's/#RUN_AS_USER="www-data"/RUN_AS_USER="ubuntu"/' /etc/default/hhvm
service hhvm start

# Start HHVM On System Start

update-rc.d hhvm defaults

# Setup Some PHP-FPM Options

ln -s /etc/php5/mods-available/mailparse.ini /etc/php5/fpm/conf.d/20-mailparse.ini

sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php5/fpm/php.ini
sed -i "s/display_errors = .*/display_errors = On/" /etc/php5/fpm/php.ini
sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php5/fpm/php.ini
sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php5/fpm/php.ini
sed -i "s/upload_max_filesize = .*/upload_max_filesize = 100M/" /etc/php5/fpm/php.ini
sed -i "s/post_max_size = .*/post_max_size = 100M/" /etc/php5/fpm/php.ini
sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php5/fpm/php.ini

echo "xdebug.remote_enable = 1" >> /etc/php5/fpm/conf.d/20-xdebug.ini
echo "xdebug.remote_connect_back = 1" >> /etc/php5/fpm/conf.d/20-xdebug.ini
echo "xdebug.remote_port = 9000" >> /etc/php5/fpm/conf.d/20-xdebug.ini
echo "xdebug.max_nesting_level = 250" >> /etc/php5/fpm/conf.d/20-xdebug.ini

# Copy fastcgi_params to Nginx because they broke it on the PPA

cat > /etc/nginx/fastcgi_params << EOF
fastcgi_param   QUERY_STRING        \$query_string;
fastcgi_param   REQUEST_METHOD      \$request_method;
fastcgi_param   CONTENT_TYPE        \$content_type;
fastcgi_param   CONTENT_LENGTH      \$content_length;
fastcgi_param   SCRIPT_FILENAME     \$request_filename;
fastcgi_param   SCRIPT_NAME     \$fastcgi_script_name;
fastcgi_param   REQUEST_URI     \$request_uri;
fastcgi_param   DOCUMENT_URI        \$document_uri;
fastcgi_param   DOCUMENT_ROOT       \$document_root;
fastcgi_param   SERVER_PROTOCOL     \$server_protocol;
fastcgi_param   GATEWAY_INTERFACE   CGI/1.1;
fastcgi_param   SERVER_SOFTWARE     nginx/\$nginx_version;
fastcgi_param   REMOTE_ADDR     \$remote_addr;
fastcgi_param   REMOTE_PORT     \$remote_port;
fastcgi_param   SERVER_ADDR     \$server_addr;
fastcgi_param   SERVER_PORT     \$server_port;
fastcgi_param   SERVER_NAME     \$server_name;
fastcgi_param   HTTPS           \$https if_not_empty;
fastcgi_param   REDIRECT_STATUS     200;
EOF

# Set The Nginx & PHP-FPM User

sed -i "s/user www-data;/user ubuntu;/" /etc/nginx/nginx.conf
sed -i "s/# server_names_hash_bucket_size.*/server_names_hash_bucket_size 64;/" /etc/nginx/nginx.conf

sed -i "s/user = www-data/user = ubuntu/" /etc/php5/fpm/pool.d/www.conf
sed -i "s/group = www-data/group = ubuntu/" /etc/php5/fpm/pool.d/www.conf

sed -i "s/listen\.owner.*/listen.owner = ubuntu/" /etc/php5/fpm/pool.d/www.conf
sed -i "s/listen\.group.*/listen.group = ubuntu/" /etc/php5/fpm/pool.d/www.conf
sed -i "s/;listen\.mode.*/listen.mode = 0666/" /etc/php5/fpm/pool.d/www.conf

service nginx restart
service php5-fpm restart

# Add ubuntu User To WWW-Data

usermod -a -G www-data ubuntu
id ubuntu
groups ubuntu

# Install Node

apt-get install -y nodejs
/usr/bin/npm install -g grunt-cli
/usr/bin/npm install -g gulp
/usr/bin/npm install -g bower

# Install SQLite

apt-get install -y sqlite3 libsqlite3-dev

# Install A Few Other Things

apt-get install -y memcached
