#!/bin/bash

sudo apt update -y
sudo apt upgrade -y

sudo apt install -y curl php-fpm php-mysql mysql-server nginx php-xml php-curl php-mbstring php-zip unzip redis-server jq

sudo systemctl start redis-server
sudo systemctl enable redis-server

sudo mysql_secure_installation <<EOF

y
$MYSQL_ROOT_PASSWORD
$MYSQL_ROOT_PASSWORD
y
y
y
y
EOF

echo "Configuring MySQL to allow remote connections..."
sudo sed -i '/^bind-address/s/^/# /' /etc/mysql/mysql.conf.d/mysqld.cnf  # Comment out the existing bind-address line
echo "bind-address = 0.0.0.0" | sudo tee -a /etc/mysql/mysql.conf.d/mysqld.cnf  # Add new bind-address line
sudo systemctl restart mysql  # Restart MySQL to apply changes


if ! command -v aws &> /dev/null; then
    echo "AWS CLI not found. Installing AWS CLI..."
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
fi

AWS_ENV_SECRET_NAME="prod/env"
AWS_REGION="us-east-1"  
env_json=$(aws secretsmanager get-secret-value --secret-id $AWS_ENV_SECRET_NAME --query SecretString --output text --region $AWS_REGION)

db_password=$(echo "$env_json" | jq -r '.DB_PASSWORD')

echo "Creating MySQL user 'laravel' with access to all databases..."
sudo mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "CREATE USER IF NOT EXISTS 'laravel'@'localhost' IDENTIFIED BY '$db_password';"
sudo mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "GRANT ALL PRIVILEGES ON *.* TO 'laravel'@'localhost' WITH GRANT OPTION;"
sudo mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "FLUSH PRIVILEGES;"
sudo mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "CREATE DATABASE IF NOT EXISTS laravel;"

PHP_FPM_SOCK=$(find /var/run/php/ -name "php*-fpm.sock" | head -n 1)  # Dynamically find PHP-FPM socket
cat <<EOL | sudo tee /etc/nginx/sites-available/default
server {
    listen 80;
    server_name _;

    root /var/www/html/public;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:$PHP_FPM_SOCK;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOL

# Restart Nginx to apply changes
sudo systemctl restart nginx

echo "Installing Composer..."
curl -sS https://getcomposer.org/installer -o composer-setup.php
if [ -f "composer-setup.php" ]; then
    sudo php composer-setup.php --install-dir=/usr/local/bin --filename=composer
    sudo chmod +x /usr/local/bin/composer
    echo "Composer installed successfully."
else
    echo "Failed to download Composer installer."
    exit 1
fi

sudo apt install -y git
sudo rm -rf /var/www/html/*
sudo git clone https://github.com/janamkhatiwada/laravel-todolist-api.git /var/www/html
cd /var/www/html

sudo chown -R www-data:www-data /var/www/html


echo "$env_json" | jq -r 'to_entries|map("\(.key)=\(.value)")|.[]' | sudo tee /var/www/html/.env > /dev/null

sudo chmod -R 755 /var/www/html/storage
sudo chmod -R 755 /var/www/html/bootstrap/cache
git config --global --add safe.directory /var/www/html

sudo -u www-data composer install
sudo php artisan key:generate
sudo -u www-data php artisan migrate --seed
sudo -u www-data php artisan config:cache

echo "Laravel setup and configuration complete."
