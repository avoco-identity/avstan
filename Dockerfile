FROM php:7.4-cli

# Install dependencies and PHP extensions needed for typical projects
# Use multi-stage installation and parallelization to speed up build
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libzip-dev \
    libicu-dev \
    libxml2-dev \
    libonig-dev \
    && docker-php-ext-configure intl \
    && docker-php-ext-install -j$(nproc) \
       zip \
       intl \
       bcmath \
       mbstring \
       xml \
       pdo \
       pdo_mysql \
    && rm -rf /var/lib/apt/lists/*

# Install MongoDB extension version 1.12.0 (last version compatible with PHP 7.4)
RUN pecl channel-update pecl.php.net && \
    pecl install mongodb-1.12.0 && \
    docker-php-ext-enable mongodb

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install PHPStan
RUN curl -L https://github.com/phpstan/phpstan/releases/latest/download/phpstan.phar -o /phpstan && \
    chmod a+x /phpstan

# Create directory for configuration
RUN mkdir -p /phpstan-config

# Copy default PHPStan configuration
COPY phpstan.neon.dist /phpstan-config/phpstan.neon.dist

# Copy entrypoint script
COPY "entrypoint.sh" "/entrypoint.sh"
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
