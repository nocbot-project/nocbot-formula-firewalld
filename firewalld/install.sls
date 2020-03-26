{%- from "firewalld/map.jinja" import firewalld with context %}

{%- if firewalld.get('enabled', False) %}

firewalld__pkg:
  pkg.installed:
    - name: {{ firewalld.pkg_name }}
    {%- if firewalld.version is defined %}
    - version: {{ firewalld.version }}
    {%- endif %}
    - require_in:
        - service: firewalld__service
    - watch_in:
        - service: firewalld__service

{%- endif %}