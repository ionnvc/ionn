# Located in: /etc/nginx/sites-available/www.gitlab.com

# You may add here your
# server {
#	...
# }
# statements for each of your virtual hosts to this file

##
# You should look at the following URL's in order to grasp a solid understanding
# of Nginx configuration files in order to fully unleash the power of Nginx.
# http://wiki.nginx.org/Pitfalls
# http://wiki.nginx.org/QuickStart
# http://wiki.nginx.org/Configuration
#
# Generally, you will want to move this file somewhere, and start with a clean
# file but keep this around for reference. Or just disable in sites-enabled.
#
# Please see /usr/share/doc/nginx-doc/examples/ for more detailed examples.
##


server {
	listen   80; ## listen for ipv4; this line is default and implied
	root /home/deploy/public;
	index index.html;
        add_header X-Frame-Options DENY;
	server_name localhost www.gitlab.com blue-moon.gitlap.com;
    server_tokens off;
    client_max_body_size 10M;

	location / {
		# First attempt to serve request as file, then
		# as directory, then fall back to index.html
		#try_files $uri $uri/;
		# Uncomment to enable naxsi on this location
		# include /etc/nginx/naxsi.rules
	}

	# Only for nginx-naxsi : process denied requests
	#location /RequestDenied {
		# For example, return an error code
		#return 418;
	#}

	#error_page 404 /404.html;

	# redirect server error pages to the static page /50x.html
	#
	#error_page 500 502 503 504 /50x.html;
	#location = /50x.html {
	#	root /usr/share/nginx/www;
	#}

	# pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
	#
	#location ~ \.php$ {
	#	fastcgi_split_path_info ^(.+\.php)(/.+)$;
	#	# NOTE: You should have "cgi.fix_pathinfo = 0;" in php.ini
	#
	#	# With php5-cgi alone:
	#	fastcgi_pass 127.0.0.1:9000;
	#	# With php5-fpm:
	#	fastcgi_pass unix:/var/run/php5-fpm.sock;
	#	fastcgi_index index.php;
	#	include fastcgi_params;
	#}

	# deny access to .htaccess files, if Apache's document root
	# concurs with nginx's one
	#
	#location ~ /\.ht {
	#	deny all;
	#}
}


# another virtual host using mix of IP-, name-, and port-based configuration
#
#server {
#	listen 8000;
#	listen somename:8080;
#	server_name somename alias another.alias;
#	root html;
#	index index.html index.htm;
#
#	location / {
#		try_files $uri $uri/ /index.html;
#	}
#}

# HTTPS server
#
server {
	listen 443;
	root /home/deploy/public;
	index index.html;
        add_header X-Frame-Options DENY;
	server_name localhost www.gitlab.com blue-moon.gitlap.com;
    server_tokens off;
    client_max_body_size 10M;

	ssl on;
	ssl_certificate /etc/ssl/www.gitlab.com.pem;
	ssl_certificate_key /etc/ssl/www.gitlab.com.key;

	ssl_session_timeout 5m;

	# ssl_protocols SSLv3 TLSv1;
    ssl_ciphers RC4:HIGH:!aNULL:!MD5;
	ssl_prefer_server_ciphers on;

	location / {
	}
}
