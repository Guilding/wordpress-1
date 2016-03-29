#!/bin/bash

consul-template \
    -once \
    -dedup \
    -consul {{.CONSUL}} \
    -template "/var/www/html/memcached-config.php.ctmpl:/var/www/html/memcached-config.php"

consul-template \
    -once \
    -dedup \
    -consul {{.CONSUL}} \
    -template "/var/www/html/memcached-admin-config.php.ctmpl:/var/www/html/tools/MemcachedAdmin/Config/Memcache.php"
