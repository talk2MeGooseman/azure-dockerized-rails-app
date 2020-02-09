# Dockerized Ruby on Rails 6 Application for Azure Web Apps

This is an example dockerized Rails application using sqlite to avoid any databased dependency for initial test run.

## Adjustment made to the Rails code

- Removed `gem 'spring-watcher-listen'` from `Gemfile`

- Disable the Yarn integrity check in `webpacker.yml`

```check_yarn_integrity: false```

- Add your domain to hosts in your `config/environments/production.rb`

```config.hosts << "http://[url-here].azurewebsites.net/"```

## Files for Dockerizing the Rails app

- Dockerfile
- docker-compose.yml
- entrypoints/docker-entrypoint.sh
- .dockerignore
