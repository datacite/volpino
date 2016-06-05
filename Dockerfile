FROM phusion/passenger-full:0.9.18
MAINTAINER Martin Fenner "mfenner@datacite.org"

# Set correct environment variables
ENV HOME /home/app

# Allow app user to read /etc/container_environment
RUN usermod -a -G docker_env app

# Use baseimage-docker's init process
CMD ["/sbin/my_init"]

# Update installed APT packages, clean up when done
RUN apt-get update && \
    apt-get upgrade -y -o Dpkg::Options::="--force-confold" && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Enable Passenger and Nginx and remove the default site
# Preserve env variables for nginx
RUN rm -f /etc/service/nginx/down && \
    rm /etc/nginx/sites-enabled/default
COPY vendor/docker/webapp.conf /etc/nginx/sites-enabled/webapp.conf
COPY vendor/docker/00_app_env.conf /etc/nginx/conf.d/00_app_env.conf
COPY vendor/docker/cors.conf /etc/nginx/conf.d/cors.conf

# Enable the memcached service
RUN rm -f /etc/service/memcached/down

# Prepare shared folder
RUN mkdir -p /home/app/webapp/shared
COPY vendor /home/app/webapp/shared/vendor
RUN chown -R app:app /home/app/webapp/shared && \
    chmod -R 755 /home/app/webapp/shared

# Install npm and bower packages
WORKDIR /home/app/webapp/shared/vendor
RUN sudo -u app npm install

# Install Ruby gems
COPY Gemfile /home/app/webapp/shared/Gemfile
COPY Gemfile.lock /home/app/webapp/shared/Gemfile.lock
WORKDIR /home/app/webapp/shared
RUN gem install bundler
RUN sudo -u app bundle install --path vendor/bundle

# Copy webapp folder
ADD . /home/app/webapp/current
WORKDIR /home/app/webapp/current
RUN chown -R app:app /home/app/webapp/current && \
    chmod -R 755 /home/app/webapp/current

# Run additional scripts during container startup (i.e. not at build time)
RUN mkdir -p /etc/my_init.d
COPY vendor/docker/70_symlink.sh /etc/my_init.d/70_symlink.sh
COPY vendor/docker/80_cron.sh /etc/my_init.d/80_cron.sh
COPY vendor/docker/90_migrate.sh /etc/my_init.d/90_migrate.sh

# Expose web
EXPOSE 80
