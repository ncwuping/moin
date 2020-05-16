#!/usr/bin/env bash

set -e

{
  echo "# -*- coding: utf-8 -*-"
  echo ""
  echo "import os"
  echo "import gevent.monkey"
  echo "gevent.monkey.patch_all()"
  echo ""
  echo "import multiprocessing"
  echo "bind = '0.0.0.0:${PORT:-8000}'"
  if [ "${MULTI_PROC}" = "Y" ]; then
    echo "workers = multiprocessing.cpu_count() * 2 + 1"
  fi
  echo "worker_class = 'gevent'"
  echo ""
  echo "user = '${USER:-root}'"
  echo "loglevel = 'warning'"
  echo "pidfile = '/var/run/gunicorn.pid'"
  echo "accesslog = '/var/log/gunicorn/access.log'"
  echo "errorlog = '/var/log/gunicorn/error.log'"
  echo "#daemon = 'True'"
  echo "#keyfile = '/etc/pki/tls/private/ssl-key.pem'"
  echo "#certfile = '/etc/pki/tls/certs/ssl-cert.pem'"
} > /etc/gunicorn.py

mkdir -p /var/log/gunicorn

cd /usr/share/moin
cp -a server/moin.wsgi moin_wsgi.py
cp -a config/wikiconfig.py ./
sed -E 's!^(\s*)(url_prefix_static = '"'"'/mywiki'"'"' \+ url_prefix_static)!\1#\2!' -i wikiconfig.py
if [ ! "${TITLE}" = "" ]; then
  sed -i 's!Untitled Wiki!'"${TITLE}"'!' -i wikiconfig.py
fi
sed -i '/#superuser/a\    superuser = [u\"admin\", ]' wikiconfig.py
sed -i '/#acl_rights_before/a\    acl_rights_before = u\"admin:read,write,delete,revert,admin+AdminGroup:admin\"' wikiconfig.py
if [ ! "${LANG_DEF}" = "" ]; then
  sed -E 's!^(\s*language_default = '"'"')en'"'"'!\1'"${LANG_DEF}'"'!' -i wikiconfig.py
fi
sed -i '$a\    tz_offset = 8.0' wikiconfig.py
sed -i '$a\    log_reverse_dns_lookups = False' wikiconfig.py

if [ ! -d "/usr/share/moin/data" ]; then
  mv -f /usr/share/moin/data.template /usr/share/moin/data
fi

if [ "$( ls -A data )" = "" ]; then
  mv -f data.template/* data/
fi

if [ -d "/usr/share/moin/data.template" ]; then
  rm -rf /usr/share/moin/data.template
fi

exec "$@"
