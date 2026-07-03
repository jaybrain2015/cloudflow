FROM php:8.3-fpm-alpine

# runtime: nginx + supervisor, and the pdo_mysql extension to talk to MySQL
RUN apk add --no-cache nginx supervisor \
    && docker-php-ext-install pdo pdo_mysql

WORKDIR /var/www/html


COPY public/ ./public/
COPY docker/nginx.conf /etc/nginx/http.d/default.conf
COPY docker/supervisord.conf /etc/supervisord.conf

EXPOSE 8080
CMD ["supervisord", "-c", "/etc/supervisord.conf"]
