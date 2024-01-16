FROM php:8.2-fpm

# Set default values for build arguments
ARG uid=1000
ARG user=myuser
ENV HOST 0.0.0.0
EXPOSE 8080

# Install dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    nodejs \
    npm \
    zip \
    unzip


RUN apt clean && rm -rf /var/lib/apt/lists/*
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www

# Copy Laravel project files
COPY . .


# Run necessary commands
RUN composer install --no-dev --optimize-autoloader
RUN composer require laravel/ui
RUN php artisan ui bootstrap --auth
RUN npm install
RUN npm run build
RUN npm run production


# Create a non-root user
RUN useradd -G www-data,root -u $uid -d /home/$user $user
RUN mkdir -p /home/$user/.composer && \
    chown -R $user:$user /home/$user

# Set ownership and permissions for storage and bootstrap/cache
RUN chown -R $user:$user /var/www/storage /var/www/bootstrap/cache \
    && chmod -R 775 /var/www/storage /var/www/bootstrap/cache

# Switch to the non-root user
USER $user

# Copy the entry script
COPY entrypoint.sh /var/www/entrypoint.sh

# Change ownership of the entry script
USER root
RUN chown $user:$user /var/www/entrypoint.sh

# Switch back to the non-root user
USER $user

# Set executable permissions for the entry script
RUN chmod +x /var/www/entrypoint.sh

# Use entrypoint.sh as the CMD
CMD ["/var/www/entrypoint.sh"]
