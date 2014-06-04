{% from 'buildbot/config.jinja' import base_config, slave_config with context %}

{% set master_name = slave_config('master_name') %}
{% set master_port = slave_config('master_port') %}
{% set slave_name = slave_config('slave_name') %}
{% set slave_password = slave_config('slave_password') %}

{% set home = base_config('home') %}
{% set user = base_config('user') %}

{% if base_config('install_slave') == 'true' %}

buildbot_slave_check:
  cmd.run:
    - name: "[ -d {{ home }}/slave ]; if [ $? == 1 ]; then echo -e '\nchanged=true'; fi"
    - stateful: True
    - require:
      - sls: buildbot.base

buildbot_slave_pip:
  pip.installed:
    - name: buildbot-slave
    - user: {{ user }}
    - bin_env: {{ home }}/bin/pip
    - require:
      - sls: buildbot.base

buildbot_slave:
  cmd.wait:
    - name: 'buildslave create-slave slave {{ master_name }}:{{ master_port }} {{ slave_name }} {{ slave_password }}'
    - user: {{ user }}
    - cwd:  {{ home }}
    - env:
      - PATH: '$PATH:{{ home }}/bin'
    - watch:
      - cmd: buildbot_slave_check
    - require:
      - pip: buildbot_slave_pip

buildbot_slave_upstart:
  file.managed:
    - name: /etc/init/buildslave.conf
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - source: salt://buildbot/files/buildslave.conf
    - require:
      - sls: buildbot.base
    - context:
        user: {{ user }}
        home: {{ home }}

buildslave_service:
  service.running:
    - name: buildslave
    - require:
      - file: buildbot_slave_upstart

{% endif %}
