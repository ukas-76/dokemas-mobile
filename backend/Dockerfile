FROM php:8.4-fpm-alpine

WORKDIR /var/www/html

RUN apk add --no-cache nginx supervisor libpng libwebp libjpeg-turbo freetype oniguruma curl ca-certificates nodejs npm \
    && apk add --no-cache --virtual .build-deps libpng-dev libwebp-dev libjpeg-turbo-dev freetype-dev oniguruma-dev libxml2-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install -j$(nproc) pdo pdo_mysql mbstring exif pcntl bcmath gd xml opcache \
    && apk del .build-deps

COPY --from=composer:2.8 /usr/bin/composer /usr/bin/composer

COPY . .

RUN composer install --no-interaction --no-scripts --no-dev --optimize-autoloader \
    && if [ -f package.json ]; then npm install && npm run build; fi \
    && cp .env.example .env \
    && chmod +x docker/start.sh \
    && chown -R nginx:nginx public \
    && chown -R nobody:nobody storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

COPY docker/nginx.conf /etc/nginx/nginx.conf
COPY docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 80
CMD ["/var/www/html/docker/start.sh"]
