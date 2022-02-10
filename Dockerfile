FROM php:7.4-cli

RUN curl -L https://github.com/phpstan/phpstan/raw/master/phpstan.phar -o /phpstan

COPY "entrypoint.sh" "/entrypoint.sh"


RUN chmod +x /entrypoint.sh && chmod a+x /phpstan
ENTRYPOINT ["/entrypoint.sh"]
