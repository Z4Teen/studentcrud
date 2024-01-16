#!/bin/sh

# Run database migrations
php artisan migrate --force

# Start the application
php -S 0.0.0.0:8080 -t public
