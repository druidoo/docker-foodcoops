FROM druidoo/odoo:9.0.base

# Add other dependencies
USER root
RUN apt-get update \
    && apt-get install -y \
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
        python-redis \
        swig \
    # pip dependencies that require build deps
    && pip install pycurl \
    # purge
    #&& apt-get purge -yqq build-essential '*-dev' make \
    && apt-get -yqq autoremove \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
USER odoo

# Aggregate new repositories of this image
COPY foodcoops.yml $RESOURCES/
RUN autoaggregate --config "$RESOURCES/foodcoops.yml" --install --output $SOURCES

# Create symlinks to simulate standard odoo deployment
RUN    ln -s $SOURCES/odoo $SOURCES/AwesomeFoodCoops/odoo \
	&& ln -s $SOURCES/repositories/OCA_addons $SOURCES/AwesomeFoodCoops/OCA_addons \
	&& ln -s $SOURCES/repositories/extra_addons $SOURCES/AwesomeFoodCoops/extra_addons \
	&& ln -s $SOURCES/repositories/intercoop_addons $SOURCES/AwesomeFoodCoops/intercoop_addons \
	&& ln -s $SOURCES/repositories/chouettecoop_addons $SOURCES/AwesomeFoodCoops/chouettecoop_addons \
	&& ln -s $SOURCES/repositories/louve_addons $SOURCES/AwesomeFoodCoops/louve_addons \
	&& ln -s $SOURCES/repositories/lacagette_addons $SOURCES/AwesomeFoodCoops/lacagette_addons \
	&& ln -s $SOURCES/repositories/smile_addons $SOURCES/AwesomeFoodCoops/smile_addons \
	&& ln -s $SOURCES/repositories/superquinquin_addons $SOURCES/AwesomeFoodCoops/superquinquin_addons \
	&& pip install --user --no-cache-dir $SOURCES/odoo

# Add patched server.py. Hacked to avoid creating a new database if it doesn't exist, when sending db_name
ADD server.py /home/odoo/.local/lib/python3.5/site-packages/odoo/cli/

# Add new entrypoints and configs
COPY entrypoint.d/* $RESOURCES/entrypoint.d/
COPY conf.d/* $RESOURCES/conf.d/

