#!/bin/sh

TEMPLATE=/etc/nginx/conf.d/ssl.conf.template
BOOTSTRAP=/etc/nginx/conf.d/bootstrap.conf
TARGET=/etc/nginx/conf.d/default.conf

if [ -f /etc/letsencrypt/live/${DOMAIN_NAME}/fullchain.pem ]; then
  echo "SSL certificates found — generating HTTPS config"

  # подстановка переменных окружения в template
  envsubst '${DOMAIN_NAME}' < $TEMPLATE > $TARGET
else
  echo "No certificates — starting in HTTP bootstrap mode"
  envsubst '${DOMAIN_NAME}' < $BOOTSTRAP > $TARGET
fi

nginx -g "daemon off;"
