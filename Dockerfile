FROM centos:7

COPY docker-entrypoint.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/docker-entrypoint.sh \
 && mkdir -p /docker-entrypoint-initdb.d \
 && ln -s usr/local/bin/docker-entrypoint.sh /
ENTRYPOINT ["docker-entrypoint.sh"]

RUN yum -y clean all \
 && yum makecache fast \
 && yum -y install epel-release \
 && yum -y update; \
    curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py \
 && python get-pip.py --no-wheel \
 && rm -f get-pip.py; \
    pip install -i https://pypi.tuna.tsinghua.edu.cn/simple gunicorn gevent -U \
 && yum -y install moin \
 && yum -y clean all \
 && rm -rf /var/cache/yum \
 && mv -f /usr/share/moin/data /usr/share/moin/data.template

EXPOSE 8000

STOPSIGNAL SIGTERM

CMD ["/usr/bin/python", "/usr/bin/gunicorn", "--config", "/etc/gunicorn.py", "--chdir", "/usr/share/moin", "moin_wsgi:application;"]
