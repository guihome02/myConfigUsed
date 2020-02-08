FROM php:7.2-apache

# Set locale
RUN apt-get update && apt-get install -y locales
RUN echo fr_FR.UTF-8 UTF-8 > /etc/locale.gen && locale-gen
ENV LANG fr_FR.UTF-8
ENV LANGUAGE fr_FR:fr
ENV LC_ALL fr_FR.UTF-8

# Set timezone
ENV TZ=Europe/Paris
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install system tools
RUN apt-get update && apt-get install -y \
    acl \
    git \
    gnupg \
    unzip \
    wget

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
RUN composer --version

# Install Symfony Installer
RUN curl -LsS https://symfony.com/installer -o /usr/local/bin/symfony
RUN chmod a+x /usr/local/bin/symfony

# Install PHP extensions
RUN docker-php-ext-install pdo pdo_mysql
RUN apt-get update && apt-get install -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpng-dev \
        libicu-dev \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-configure intl \
    && docker-php-ext-configure opcache --enable-opcache \
    && docker-php-ext-install -j$(nproc) gd iconv intl opcache pcntl

# PHP configuration
COPY conf/php/opcache.ini $PHP_INI_DIR/conf.d/

# Install and enable xdebug
RUN pecl install xdebug && docker-php-ext-enable xdebug

# Install ruby for installing sass and compass
RUN apt-get update && apt-get install -y ruby-full && gem install --no-rdoc --no-ri sass -v 3.4.22 && gem install --no-rdoc --no-ri compass

# Install Cypress dependencies
RUN apt-get update && apt-get install -y \
    libgtk2.0-0 \
    libnotify-dev \
    libgconf-2-4 \
    libnss3 \
    libxss1 \
    libasound2 \
    xvfb

# Install nodejs and npm
RUN curl -sL https://deb.nodesource.com/setup_12.x | bash && apt-get update && apt-get install -y nodejs && node -v && npm -v

# Install Yarn
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
    && apt-get update \
    && apt-get install yarn \
    && yarn --version

# Add Apache2 virtual hosts
ADD conf/apache2/sites-available /etc/apache2/sites-available
RUN a2ensite sites.conf && a2enmod rewrite

RUN useradd -ms /bin/bash guihome && usermod -a -G www-data guihome
RUN echo "root:root" | chpasswd

COPY run.sh /usr/local/bin/
ENTRYPOINT run.sh
