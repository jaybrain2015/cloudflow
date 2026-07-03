# ---------- STAGE 1: builder (assembles the app + dependencies) ----------
FROM php:8.3-cli-alpine AS builder

# tools needed only to BUILD
RUN apk add --no-cache git unzip \
    && docker-php-ext-install bcmath pdo pdo_mysql

# Composer from its official image
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /app

# caching: dependency list first, install, THEN the code
COPY src/composer.json src/composer.lock ./
RUN composer install --no-dev --no-scripts --no-autoloader --no-interaction \
    --ignore-platform-req=ext-zip --ignore-platform-req=ext-gd

# now the full source, then finish the autoloader
COPY src/ ./
RUN composer dump-autoload --optimize --no-dev --no-scripts \
    --ignore-platform-req=ext-zip --ignore-platform-req=ext-gd


# ---------- STAGE 2: runtime (the lean image we ship) ----------
FROM php:8.3-fpm-alpine AS runtime

# runtime libs + temporary build headers, compile extensions, then remove headers
RUN apk add --no-cache nginx supervisor \
        libpng libjpeg-turbo freetype zlib libzip \
    && apk add --no-cache --virtual .build-deps \
        libpng-dev libjpeg-turbo-dev freetype-dev zlib-dev libzip-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install bcmath pdo pdo_mysql gd zip \
    && apk del .build-deps

WORKDIR /var/www/html

# THE multi-stage magic: copy ONLY the finished app from stage 1
COPY --from=builder /app ./

# runtime configs
COPY docker/nginx.conf /etc/nginx/http.d/default.conf
COPY docker/supervisord.conf /etc/supervisord.conf

# Laravel needs these writable
RUN chown -R www-data:www-data storage bootstrap/cache

EXPOSE 8080
CMD ["supervisord", "-c", "/etc/supervisord.conf"]