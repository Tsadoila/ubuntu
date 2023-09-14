#!/bin/bash

#To Run This Script, Use this command 
# bash <(wget -qO- https://raw.githubusercontent.com/Tsadoila/ubuntu/main/python_mysql_gunicorn_nginx_setup.sh)

while true; do
    clear
    echo "Choose what you want to install:"
    echo "1. Python 3.9 Setup"
    echo "2. MySQL Server Setup"
    echo "3. Gunicorn Service Setup For Project"
    echo "4. Nginx Reverse Proxy Setup For Project"
    echo "5. Quit"

    read -p "Enter your choice (1/2/3/4/5): " choice

    case $choice in
        1)
            echo "Running Python 3.9 Setup Script..."
            # Add your Python setup script here
            sudo apt install -y software-properties-common
            echo "" | sudo add-apt-repository ppa:deadsnakes/ppa
            sudo apt install -y python3.9
            sudo update-alternatives --install /usr/bin/python python /usr/bin/python3.9 0
            sudo apt-get install -y libreadline-dev zlib1g-dev libncursesw5-dev libssl-dev libsqlite3-dev  libgdbm-dev libc6-dev libbz2-dev
            sudo apt-get install -y build-essential libssl-dev libffi-dev  libexpat1-dev liblzma-dev python3-testresources
            sudo apt-get install -y mysql-client libmysqlclient-dev libpango-1.0-0 libpangoft2-1.0-0
            sudo apt-get install -y python3.9-dev python3-pip python3.9-distutils
            curl -sS https://bootstrap.pypa.io/get-pip.py | python3.9
            pip install --upgrade pip
            echo "Python 3.9 installation complete"
            ;;
        2)
            echo "Running MySQL Server Setup Script..."
            # Add your MySQL setup script here
            sudo apt update
            sudo apt install mysql-server
            sudo systemctl start mysql
            sudo systemctl enable mysql
            sudo mysql_secure_installation
            echo "Creating MySQL user 'edogawa_user' without a password and granting all privileges..."
            mysql -u root -p -e "CREATE USER 'edogawa_user'@'%' IDENTIFIED BY '';"
            mysql -u root -p -e "GRANT ALL PRIVILEGES ON *.* TO 'edogawa_user'@'%';"
            mysql -u root -p -e "FLUSH PRIVILEGES;"
            echo "Allowing incoming traffic on MySQL port (3306) through UFW..."
            sudo ufw allow 3306/tcp
            sudo sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mysql/mysql.conf.d/mysqld.cnf
            echo "Enabling UFW..."
            sudo ufw --force enable
            sudo systemctl restart mysql
            echo "MySQL user 'edogawa_user' created, privileges granted, MySQL port allowed through UFW, MySQL configured to listen on the server's IP address, and MySQL server is installed and secure."
            ;;
        3)
            echo "Running Gunicorn Service Setup Script..."
            # Add your Gunicorn setup script here
            HOME_DIR=$(eval echo ~$USER)
            DIRECTORY="$HOME_DIR/Child-Guidance"
            if [ ! -d "$DIRECTORY" ]; then
                echo "The 'Child-Guidance' directory does not exist. Exiting script."
                exit 1
            fi
            echo '# -*- coding: utf-8 -*-

            import multiprocessing
            from socket import gethostbyname, gethostname

            raw_env = ["DJANGO_SETTINGS_MODULE=edogawachildabuse.settings"]

            ip = gethostbyname(gethostname() + ".local")
            bind = ip + ":8000"
            workers = multiprocessing.cpu_count() * 2 + 1
            threatds = 2

            pidfile = "'"$HOME_DIR"'/Child-Guidance/gunicorn/run/gunicorn.pid"

            accesslog = "'"$HOME_DIR"'/Child-Guidance/gunicorn/log/access.log"
            access_log_format = "%(t)s %(h)s %(H)s %(m)s %(U)s %(q)s %(s)s %(a)s"
            disable_redirect_access_to_syslog = True
            errorlog = "'"$HOME_DIR"'/Child-Guidance/gunicorn/log/error.log"
            loglevel = "info"' > gunicorn/gunicorn.conf.py

            python -m pip install gunicorn
            sudo mkdir -p /usr/lib/systemd/system/
            sudo sh -c "echo '[Unit]
            Description=Python WSGI application
            After=network.target
            [Service]
            Type=simple
            User='"$USER"'
            Group='"$USER"'
            WorkingDirectory='"$HOME_DIR"'/Child-Guidance
            ExecStart='"$HOME_DIR"'/.local/bin/gunicorn edogawachildabuse.wsgi -c '"$HOME_DIR"'/Child-Guidance/gunicorn/gunicorn.conf.py
            [Install]
            WantedBy=multi-user.target' > /usr/lib/systemd/system/gunicorn.service"
            sudo systemctl daemon-reload
            sudo systemctl enable gunicorn
            sudo systemctl restart gunicorn
            sudo systemctl status gunicorn
            ;;
        4)
            echo "Running Nginx Reverse Proxy Setup Script..."
            # Add your Nginx setup script here
            echo "Installing Nginx..."
            sudo apt -y install nginx
            echo "Allowing Nginx Full profile in UFW..."
            sudo ufw allow 'Nginx Full'
            echo "Enabling Nginx to start on boot..."
            sudo systemctl enable nginx
            IPADDRESS=$(hostname -I | awk '{print $1}')
            echo "Creating custom error pages (404.html and 500.html)..."
            sudo sh -c "echo '<html>
              <head>
                <title>404 Not Found</title>
              </head>
              <body>
                <h1>404 Not Found</h1>
                <p>The requested URL was not found on this server.</p>
              </body>
            </html>' > /var/www/html/404.html"
            sudo sh -c "echo '<html>
              <head>
                <title>500 Internal Server Error</title>
              </head>
              <body>
                <h1>500 Internal Server Error</h1>
                <p>An error occurred on the server. Please try again later.</p>
              </body>
            </html>' > /var/www/html/500.html"
            sudo chown www-data:www-data /var/www/html/404.html
            sudo chown www-data:www-data /var/www/html/500.html
            echo "Configuring Nginx..."
            sudo sh -c "echo 'upstream edogawa {
                server ${IPADDRESS}:8000;
            }

            server {
                listen 80;
                server_name ${IPADDRESS};

                location / {
                    proxy_pass http://edogawa;
                    proxy_set_header Host \$host;
                    proxy_set_header X-Real-IP \$remote_addr;
                    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
                }
                location /static {
                   autoindex on;
                   alias '"$HOME_DIR"'/Child-Guidance/accounts/static/;
                }

            }' > /etc/nginx/sites-available/edogawa"
            sudo ln -s /etc/nginx/sites-available/edogawa /etc/nginx/sites-enabled/edogawa
            echo "Restarting Nginx..."
            sudo systemctl restart nginx
            sudo systemctl status nginx
            ;;
        5)
            echo "Exiting script."
            exit 0
            ;;
        *)
            echo "Invalid choice. Please select a valid option (1/2/3/4/5)."
            ;;
    esac

    read -p "Press Enter to continue..."
done
