{%- if salt['pillar.get']('firewalld') is defined %}

include:
  - firewalld.install
  - firewalld.config
  - firewalld.service

{%- endif %}