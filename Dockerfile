FROM debian:jessie

# Update the parent image.  Not really necessary but makes it easier
# checking for security holes later.
RUN apt-get update && apt-get -y dist-upgrade && rm -rf /var/lib/apt/lists/*

# Telnet is not strictly necessary but it makes debugging easier (when you can't contact the database, and so on).
RUN apt-get update && apt-get install -y \
        git-core curl apache2 php5 php5-common php5-cli php5-curl php5-json php5-mcrypt php5-mysqlnd php5-pgsql \
        php5-sqlite telnet && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y php-pear php5-dev pkg-config && \
    pecl install mongodb && \
    apt-get purge -y php-pear php5-dev pkg-config && \
    apt-get autoremove --purge -y && \
    rm -rf /var/lib/apt/lists/*

# install composer
RUN curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer && \
    chmod +x /usr/local/bin/composer

RUN echo "ServerName localhost" | tee /etc/apache2/conf-available/servername.conf && \
    a2enconf servername && \
    rm /etc/apache2/sites-enabled/000-default.conf && \
    echo 'extension=mongodb.so' > /etc/php5/mods-available/mongodb.ini && \
    php5enmod mcrypt mongodb

ADD dreamfactory.conf /etc/apache2/sites-available/dreamfactory.conf
RUN a2ensite dreamfactory && \
    a2enmod rewrite

# get app src
RUN git clone https://github.com/dreamfactorysoftware/dreamfactory.git /opt/dreamfactory && \
    cd /opt/dreamfactory && \
    git checkout $(git tag -l | egrep -v '[a-z]' | sort -V | tail -1)

WORKDIR /opt/dreamfactory

# Uncomment this line if you're building for Bluemix and using redis for your cache
#RUN composer require "predis/predis:~1.0"

# install packages
RUN composer install && \
    php artisan dreamfactory:setup --no-app-key --db_driver=pgsql --df_install=Docker

# Comment out the line above and uncomment these this line if you're building a docker image for Bluemix.  If you're
# not using redis for your cache, change the value of --cache_driver to memcached or remove it for the standard
# file based cache.  If you're using a mysql service, change db_driver to mysql
#RUN php artisan dreamfactory:setup --no-app-key --db_driver=pgsql --cache_driver=redis --df_install="Docker(Bluemix)"

RUN chown -R www-data:www-data /opt/dreamfactory

ADD docker-entrypoint.sh /docker-entrypoint.sh
ADD .env /opt/dreamfactory/.env

# Uncomment this is you are building for Bluemix and will be using ElephantSQL
#ENV BM_USE_URI=true

EXPOSE 80

CMD ["/docker-entrypoint.sh"]
