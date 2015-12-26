ec2-laravel-evn-installer
==========

在 AWS EC2 上快速架好符合 Laravel 運行的環境。 / Setup Laravel excutable enviroment on AWS EC2 quickly.

## Step 0) 登入你的 AWS EC2 / Login your AWS EC2

創建一個全新的 Ubuntu 14.04 AWS EC2 Instance，並登入你的 EC2。 / Create a brand new Ubuntu 14.04 AWS EC2 Instance, and login.

## Step 1) 安裝並執行腳本 / Install and excute the script

```bash
$ sudo -s
$ apt-get install git
$ git clone https://github.com/fukuball/ec2-laravel-evn-installer.git
$ cd ec2-laravel-evn-installer
$ sh laravel-on-ec2.sh
```

基本上這樣就已經裝好 Laravel 可以運行的環境。 / Basically, you have already complete a Laravel excutable enviroment.

## Step 2) 安裝 Laravel / Install Laravel

```bash
$ cd /var/www
$ composer create-project laravel/laravel your-project-name --prefer-dist
```

如果看到： / If you see this message:

```bash
please create a GitHub OAuth token to go over the API rate limit
```

請至 [GitHub](https://help.github.com/articles/creating-an-access-token-for-command-line-use/) 取得 token，但也可以直接按 enter 跳過。 / Please go to [GitHub](https://help.github.com/articles/creating-an-access-token-for-command-line-use/) to get token, but you can skip this by just pressing enter button.

設定 project 資料夾權限： / Setup project folder access permission:

```bash
$ chown -R ubuntu:ubuntu your-project-name
```

## Step 3) 修改 Nginx 設定 / Modify Nginx config

```bash
$ vim /etc/nginx/sites-available/your-project-name
```

進入 vim 編輯器，複製貼上以下內容，存下編輯內容後離開編輯器： / Enter vim editor, copy and past content below, save and exit the editor:

```vim
server {
    listen 80;
    server_name localhost;
    root "/var/www/your-project-name/public";

    index index.html index.htm index.php;

    charset utf-8;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_log  /var/log/nginx/your-project-name-error.log error;

    client_max_body_size 100m;

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/var/run/php5-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
    }

    location ~ /\.ht {
        deny all;
    }

}
```

連結設定檔： / Link the config file:

```bash
$ ln -s /etc/nginx/sites-available/your-project-name /etc/nginx/sites-enabled/your-project-name
```

開啓 Nginx 伺服器： / Start Nginx server:

```bash
$ service nginx restart
```

## Step 4) 完成了！ / Complete!

用你最愛的瀏覽器打開 AWS EC2 提供的 Server 網址，你就可以看到下圖。 / Use your favorite browser open the url AWS EC2 provided, and you can see the Lavavel works like below.

![laravel-demo-pic](https://raw.github.com/fukuball/ec2-laravel-evn-installer/master/laravel-demo-pic.png)

License
=========
The MIT License (MIT)

Copyright (c) 2015 fukuball

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.