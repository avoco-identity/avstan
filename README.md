# PHPStan Static Analysis Action

This GitHub Action performs static code analysis on your PHP codebase using [PHPStan](https://phpstan.org/), helping you find bugs before they happen.

## Features

- Seamless PHPStan integration in GitHub Actions workflows
- Automatic detection of PHPStan configuration files
- Optional automatic composer dependency installation
- Configurable analysis level
- Default configuration with common error suppressions for external libraries
- Customizable memory limits and autoloading

## Usage

Basic usage:

```yaml
steps:
  - uses: actions/checkout@v3
  - name: PHPStan Static Analysis
    uses: avoco-identity/avstan@main
```

Advanced usage with all options:

```yaml
steps:
  - uses: actions/checkout@v3
  - name: PHPStan Static Analysis
    uses: avoco-identity/avstan@main
    with:
      arguments: 'app/ --memory-limit=500M'
      autoload_file: 'custom-autoload.php'
      level: '5'
      configuration: 'custom-phpstan.neon'
      memory_limit: '1G'
      install_dependencies: 'true'
```

## Inputs

| Input | Description | Default |
|-------|-------------|---------|
| `arguments` | Arguments to pass to PHPStan CLI | `''` |
| `autoload_file` | Path to autoload file if not using standard vendor/autoload.php | `''` |
| `level` | PHPStan rule level (0-9, higher = stricter) | `'2'` |
| `configuration` | Path to your PHPStan configuration file | `''` |
| `memory_limit` | PHP memory limit for PHPStan | `'-1'` (unlimited) |
| `install_dependencies` | Whether to run composer install if vendor missing | `'true'` |

## Examples

### Analyze specific directories with level 5

```yaml
- name: PHPStan
  uses: avoco-identity/avstan@main
  with:
    arguments: 'app/lib app/core --level=5'
```

### Use custom configuration

```yaml
- name: PHPStan
  uses: avoco-identity/avstan@main
  with:
    configuration: '.github/phpstan/phpstan.neon'
```

### Skip automatic dependency installation

```yaml
- name: Install dependencies manually
  run: composer install --prefer-dist --no-progress

- name: PHPStan
  uses: avoco-identity/avstan@main
  with:
    install_dependencies: 'false'
```

## Default configuration

This action includes a default PHPStan configuration that ignores common errors from third-party libraries:

- MongoDB\Collection classes
- TCPDF constants and methods
- Yoti library classes
- phpseclib sign/verify methods

You can override this by providing your own configuration file. 