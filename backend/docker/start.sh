#!/bin/sh

echo "=== Starting Dokemas Backend ==="

# Create required directories
mkdir -p /run/nginx
mkdir -p /var/www/html/storage/logs
mkdir -p /var/www/html/storage/framework/sessions
mkdir -p /var/www/html/storage/framework/views
mkdir -p /var/www/html/storage/framework/cache/data
mkdir -p /var/www/html/storage/app/public
mkdir -p /var/www/html/bootstrap/cache

cd /var/www/html

# Fix permissions
chown -R nobody:nobody /var/www/html/storage /var/www/html/bootstrap/cache
chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# Ensure .env exists
if [ ! -f /var/www/html/.env ]; then
    cp /var/www/html/.env.example /var/www/html/.env 2>/dev/null || true
fi

# Ensure storage link
rm -rf /var/www/html/public/storage 2>/dev/null || true
php artisan storage:link --force 2>/dev/null || true

# Run migrations non-destructively without crashing container
echo "=== Running migrations ==="
php artisan migrate --force 2>&1 || echo "Notice: migrations skipped or already applied"

# Clear caches so dynamic env is fresh
php artisan config:clear 2>/dev/null || true
php artisan route:clear 2>/dev/null || true
php artisan view:clear 2>/dev/null || true

echo "=== Starting supervisord ==="
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
