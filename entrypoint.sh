#!/bin/bash
set -e

PHP_FULL_VERSION=$(php -r 'echo phpversion();')
PHP_EXTENSIONS=$(php -r 'echo implode(", ", get_loaded_extensions());')
MONGODB_VERSION=$(php -r 'if(extension_loaded("mongodb")) echo phpversion("mongodb"); else echo "not installed";')

# Make sure we're in the project directory
cd "${GITHUB_WORKSPACE:-/github/workspace}"

# Set Git ownership issue workaround
git config --global --add safe.directory "${GITHUB_WORKSPACE:-/github/workspace}"

# Check if we're in a valid project directory
if [ -z "$(ls)" ]; then
  echo "No code found. Did you checkout with «actions/checkout» ?"
  exit 1
fi

# Process input arguments
if [ -z "$1" ]; then
  ARGUMENTS="analyse ."
else
  ARGUMENTS="$1"
fi

# Check if level is set via environment variable
if [ -n "${PHPSTAN_LEVEL}" ] && [[ ! "$ARGUMENTS" =~ --level ]]; then
  ARGUMENTS="${ARGUMENTS} --level=${PHPSTAN_LEVEL}"
fi

# Check if we need to add 'analyse' command
if [[ ! "$ARGUMENTS" =~ ^analyse ]]; then
  echo "INFO: No analysis mode detected. Setting mode to «analyse»"
  ARGUMENTS="analyse ${ARGUMENTS}"
fi

# Composer auto-installation if enabled
if [ "${INSTALL_DEPENDENCIES}" = "true" ] && [ -f composer.json ] && ([ ! -d vendor/ ] || [ ! -f vendor/autoload.php ]); then
  echo "INFO: composer.json found but no vendor directory. Running composer install..."
  
  # Try composer install with increasing levels of platform ignoring
  if composer install --no-dev --no-progress --prefer-dist; then
    echo "INFO: Composer install completed successfully."
  elif composer install --no-dev --no-progress --prefer-dist --ignore-platform-reqs; then
    echo "INFO: Composer install completed with --ignore-platform-reqs."
  else
    echo "INFO: Trying composer install with more specific ignore flags..."
    # Try the most aggressive approach
    composer install --no-dev --no-progress --prefer-dist --ignore-platform-reqs \
      --ignore-platform-req=ext-mongodb \
      --ignore-platform-req=php \
      --no-scripts
    
    if [ $? -ne 0 ]; then
      echo "WARNING: Composer install failed. Continuing anyway, but PHPStan may not work correctly."
    else
      echo "INFO: Composer install completed with additional ignore flags."
    fi
  fi
fi

# Warning about missing autoload
if [ ! -d vendor/ ] || [ ! -f vendor/autoload.php ]; then
  echo "WARNING: No autoload detected. You may get errors from PHPStan due to missing autoload."
  echo "Consider adding this snippet to your workflow:
      - name: Install dependencies
        run: composer install --prefer-dist --no-progress --ignore-platform-reqs"
fi

# Custom autoload file
if [ -n "${PHPSTAN_AUTOLOAD_FILE}" ] && [ -f "${PHPSTAN_AUTOLOAD_FILE}" ]; then
  echo "INFO: Using custom autoload file: ${PHPSTAN_AUTOLOAD_FILE}"
  ARGUMENTS="${ARGUMENTS} --autoload-file=${PHPSTAN_AUTOLOAD_FILE}"
fi

# PHPStan configuration handling
if [ -n "${PHPSTAN_CONFIG}" ]; then
  # Use explicitly specified config file
  if [ -f "${PHPSTAN_CONFIG}" ]; then
    echo "INFO: Using explicitly specified PHPStan configuration: ${PHPSTAN_CONFIG}"
    ARGUMENTS="${ARGUMENTS} -c ${PHPSTAN_CONFIG}"
  else
    echo "WARNING: Specified configuration file ${PHPSTAN_CONFIG} not found"
  fi
elif [ -f phpstan.neon ] || [ -f phpstan.neon.dist ]; then
  # Use repository config file
  echo "INFO: PHPStan configuration file found in repository."
  if [ -f phpstan.neon ]; then
    ARGUMENTS="${ARGUMENTS} -c phpstan.neon"
  else
    ARGUMENTS="${ARGUMENTS} -c phpstan.neon.dist"
  fi
else
  # Use default config file
  echo "INFO: No PHPStan configuration found. Using default configuration."
  ARGUMENTS="${ARGUMENTS} -c /phpstan-config/phpstan.neon.dist"
fi

# Set memory limit
if [ -n "${PHP_MEMORY_LIMIT}" ]; then
  export PHP_MEMORY_LIMIT="${PHP_MEMORY_LIMIT}"
else
  export PHP_MEMORY_LIMIT="-1"
fi

# Show PHPStan version and environment info
/phpstan -V
echo "## PHP Environment:"
echo "PHP Version: ${PHP_FULL_VERSION}"
echo "PHP Extensions: ${PHP_EXTENSIONS}"
echo "MongoDB Extension Version: ${MONGODB_VERSION}"
echo "## Running PHPStan with arguments «${ARGUMENTS}»"

# Run PHPStan with configured memory limit
php -d memory_limit=${PHP_MEMORY_LIMIT} /phpstan ${ARGUMENTS}
