FROM druidoo/odoo:9.0-base

# Add custom requirements.txt
COPY requirements.txt $RESOURCES/

# Add other dependencies
USER root
RUN apt-get update && apt-get install -y \
        build-essential \
        libcups2-dev \
        libcurl4-openssl-dev \
        parallel \
        python3-dev \
        libevent-dev \
        libjpeg-dev \
        libldap2-dev \
        libsasl2-dev \
        libssl-dev \
        libxml2-dev \
        libxslt1-dev \
        libglib2.0-dev \
        libgirepository1.0-dev \
        libcairo2-dev \
        swig \
    # install custom requirements
    && pip install -r "$RESOURCES/requirements.txt" \
    # pip dependencies that require build deps
    && pip install \
        pycurl \
        redis==2.10.5 \
        simplejson \
        git+https://github.com/turnkeylinux/octohub/@master \
    # purge
    #&& apt-get purge -yqq build-essential '*-dev' make \
    && apt-get -yqq autoremove \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
USER odoo

# Aggregate new repositories of this image
COPY foodcoops.yml $RESOURCES/
RUN autoaggregate --config "$RESOURCES/foodcoops.yml" --install --output $SOURCES

# Create symlinks to simulate standard odoo deployment
RUN    ln -s $SOURCES/AwesomeFoodCoops/odoo $SOURCES/odoo \
	&& ln -s $SOURCES/AwesomeFoodCoops/OCA_addons $SOURCES/repositories/OCA_addons \
	&& ln -s $SOURCES/AwesomeFoodCoops/extra_addons $SOURCES/repositories/extra_addons \
	&& ln -s $SOURCES/AwesomeFoodCoops/intercoop_addons $SOURCES/repositories/intercoop_addons \
	&& ln -s $SOURCES/AwesomeFoodCoops/chouettecoop_addons $SOURCES/repositories/chouettecoop_addons \
	&& ln -s $SOURCES/AwesomeFoodCoops/louve_addons $SOURCES/repositories/louve_addons \
	&& ln -s $SOURCES/AwesomeFoodCoops/lacagette_addons $SOURCES/repositories/lacagette_addons \
	&& ln -s $SOURCES/AwesomeFoodCoops/smile_addons $SOURCES/repositories/smile_addons \
	&& ln -s $SOURCES/AwesomeFoodCoops/superquinquin_addons $SOURCES/repositories/superquinquin_addons \
	&& pip install --user --no-cache-dir $SOURCES/odoo

# Add patched server.py. Hacked to avoid creating a new database if it doesn't exist, when sending db_name
ADD server.py /home/odoo/.local/lib/python2.7/site-packages/openerp/cli/

# Simulate odoo bin
RUN cp /home/odoo/.local/bin/openerp-server /home/odoo/.local/bin/odoo

# Add repositories
ARG GITHUB_USER
ARG GITHUB_TOKEN
ENV GITHUB_USER="$GITHUB_USER"
ENV GITHUB_TOKEN="$GITHUB_TOKEN"
COPY repos.yml $RESOURCES/
RUN autoaggregate --config "$RESOURCES/repos.yml" --install --output $SOURCES/repositories

# Add new entrypoints and configs
COPY bin/* /usr/local/bin/
COPY entrypoint.d/* $RESOURCES/entrypoint.d/
COPY conf.d/* $RESOURCES/conf.d/
