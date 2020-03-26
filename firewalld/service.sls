{%- from "firewalld/map.jinja" import firewalld with context %}

{%- if firewalld.get('enabled', False) %}

{%- if firewalld.get('started', False) %}
firewalld__service:
  service.running:
    - name: {{ firewalld.service }}
    - enable: {{ firewalld.get('started', False) }}
    - reload: True
    - require:
      - pkg: firewalld__pkg
    - watch:
      - pkg: firewalld__pkg
      - file: /etc/firewalld/firewalld.conf
{%- else %}
firewalld__service:
  service.dead:
    - name: {{ firewalld.service }}
    - enable: {{ firewalld.get('started', False) }}
    - require:
      - pkg: firewalld__pkg
    - watch:
      - pkg: firewalld__pkg
{%- endif %}

{%- endif %}