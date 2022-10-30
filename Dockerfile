FROM ubuntu:20.04
MAINTAINER Odoo S.A. <info@odoo.com>

SHELL ["/bin/bash", "-xo", "pipefail", "-c"]


#修改亚洲时区
ENV TZ=Asia/Shanghai
 
RUN echo "${TZ}" > /etc/timezone \
    && ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime \
    && apt update \
    && apt install -y tzdata \
    && rm -rf /var/lib/apt/lists/*

# Generate locale C.UTF-8 for postgres and general locale data
ENV LANG C.UTF-8

# Install some deps, lessc and less-plugin-clean-css, and wkhtmltopdf
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        dirmngr \
        fonts-noto-cjk \
        gnupg \
        libssl-dev \
        node-less \
        npm \
        python3-num2words \
        python3-pdfminer \
        python3-pip \
        python3-phonenumbers \
        python3-pyldap \
        python3-qrcode \
        python3-renderpm \
        python3-setuptools \
        python3-slugify \
        python3-vobject \
        python3-watchdog \
        python3-xlrd \
        python3-xlwt \
        xz-utils \
        tofrodos \
        build-essential \
        python3-dev \
        libffi-dev \
        libxml2 \
        libxml2-dev \
        libxslt1-dev \
        zlib1g-dev \
        libsasl2-dev \
        libldap2-dev \
    && curl -o wkhtmltox.deb -sSL http://10.10.20.1:5000/wkhtmltox_0.12.6-1.focal_amd64.deb \
    # && echo 'ea8277df4297afc507c61122f3c349af142f31e5 wkhtmltox.deb' | sha1sum -c - \
    && apt-get install -y --no-install-recommends ./wkhtmltox.deb \
    && rm -rf /var/lib/apt/lists/* wkhtmltox.deb

# install latest postgresql-client
ENV DEBIAN_FRONTEND=noninteractive
ARG http_proxy "http://10.10.20.1:7890"
ARG https_proxy "https://10.10.20.1:7890"
RUN echo "nameserver 8.8.8.8" >> /etc/resolv.conf
RUN echo 'deb http://apt.postgresql.org/pub/repos/apt/ bullseye-pgdg main' > /etc/apt/sources.list.d/pgdg.list \
    && GNUPGHOME="$(mktemp -d)" \
    && export GNUPGHOME \
    && repokey='B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8' \
    && gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "${repokey}" \
    && gpg --batch --armor --export "${repokey}" > /etc/apt/trusted.gpg.d/pgdg.gpg.asc \
    && gpgconf --kill all \
    && rm -rf "$GNUPGHOME" \
    && apt-get update  \
    && apt-get install --no-install-recommends -y postgresql-client \
    && rm -f /etc/apt/sources.list.d/pgdg.list \
    && rm -rf /var/lib/apt/lists/*




# Install rtlcss (on Debian buster)
RUN npm install -g rtlcss

RUN mv /etc/apt/sources.list /etc/apt/sources_backup.list && \
echo "deb http://mirrors.ustc.edu.cn/ubuntu/ focal main restricted " >> /etc/apt/sources.list && \
echo "deb http://mirrors.ustc.edu.cn/ubuntu/ focal-updates main restricted " >> /etc/apt/sources.list && \
echo "deb http://mirrors.ustc.edu.cn/ubuntu/ focal universe " >> /etc/apt/sources.list && \
echo "deb http://mirrors.ustc.edu.cn/ubuntu/ focal-updates universe " >> /etc/apt/sources.list && \
echo "deb http://mirrors.ustc.edu.cn/ubuntu/ focal multiverse " >> /etc/apt/sources.list && \
echo "deb http://mirrors.ustc.edu.cn/ubuntu/ focal-updates multiverse " >> /etc/apt/sources.list && \
echo "deb http://mirrors.ustc.edu.cn/ubuntu/ focal-backports main restricted universe multiverse " >> /etc/apt/sources.list && \
echo "deb http://mirrors.ustc.edu.cn/ubuntu/ focal-security main restricted " >> /etc/apt/sources.list && \
echo "deb http://mirrors.ustc.edu.cn/ubuntu/ focal-security universe " >> /etc/apt/sources.list && \
echo "deb http://mirrors.ustc.edu.cn/ubuntu/ focal-security multiverse " >> /etc/apt/sources.list && \
echo "deb http://archive.canonical.com/ubuntu focal partner " >> /etc/apt/sources.list
RUN apt update

# Install Odoo
ENV ODOO_VERSION 14.0
ARG ODOO_RELEASE=20220915
ARG ODOO_SHA=263af0514d9354069c62bbe9d552c3fea01e918f
ARG http_proxy "http://10.10.20.1:7890"
ARG https_proxy "https://10.10.20.1:7890"
RUN curl -o odoo.deb -sSL http://nightly.odoo.com/${ODOO_VERSION}/nightly/deb/odoo_${ODOO_VERSION}.${ODOO_RELEASE}_all.deb \
    && echo "${ODOO_SHA} odoo.deb" | sha1sum -c - \
    && apt-get update \
    && apt-get -y install --no-install-recommends ./odoo.deb \
    && rm -rf /var/lib/apt/lists/* odoo.deb

# Copy entrypoint script and Odoo configuration file
COPY ./entrypoint.sh /
COPY ./odoo.conf /etc/odoo/

# Set permissions and Mount /var/lib/odoo to allow restoring filestore and /mnt/extra-addons for users addons
ARG http_proxy "http://10.10.20.1:7890"
ARG https_proxy "https://10.10.20.1:7890"
RUN chown odoo /etc/odoo/odoo.conf \
    && mkdir -p /mnt/extra-addons \
    && chown -R odoo /mnt/extra-addons
VOLUME ["/var/lib/odoo", "/mnt/extra-addons"]

# Set permissions and Mount /var/lib/odoo to allow restoring filestore and /mnt/development-addons for users addons
ARG http_proxy "http://10.10.20.1:7890"
ARG https_proxy "https://10.10.20.1:7890"
RUN chown odoo /etc/odoo/odoo.conf \
    && mkdir -p /mnt/development-addons \
    && chown -R odoo /mnt/development-addons
VOLUME ["/var/lib/odoo", "/mnt/development-addons"]

# Set permissions and Mount /var/lib/odoo to allow restoring filestore and /mnt/oca-addons for users addons
ARG http_proxy "http://10.10.20.1:7890"
ARG https_proxy "https://10.10.20.1:7890"
RUN chown odoo /etc/odoo/odoo.conf \
    && mkdir -p /mnt/oca-addons \
    && chown -R odoo /mnt/oca-addons
VOLUME ["/var/lib/odoo", "/mnt/oca-addons"]

# Expose Odoo services
EXPOSE 8069 8071 8072

# Set the default config file
ENV ODOO_RC /etc/odoo/odoo.conf

COPY wait-for-psql.py /usr/local/bin/wait-for-psql.py

# Set default user when running the container
USER odoo

ENTRYPOINT ["/entrypoint.sh"]
CMD ["odoo"]
