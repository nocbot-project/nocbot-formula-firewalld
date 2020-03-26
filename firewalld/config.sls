{%- from "firewalld/map.jinja" import firewalld with context %}

{%- if firewalld.get('enabled', False) %}
firewalld__/etc/firewalld:
  file.directory:
    - name: /etc/firewalld
    - user: root
    - group: root
    - mode: '0750'
    - require:
      - pkg: firewalld__pkg

firewalld__/etc/firewalld/firewalld.conf:
  file.managed:
    - name: /etc/firewalld/firewalld.conf
    - user: root
    - group: root
    - mode: '0644'
    - source: salt://firewalld/files/etc/firewalld/firewalld.conf
    - template: jinja
    - require:
      - pkg: firewalld__pkg
      - file: firewalld__/etc/firewalld

{%- if firewalld.services is defined and firewalld.services is mapping %}
{%- for service_name, service in firewalld.services.items()  %}
firewalld__{{ service_name }}:
  firewalld.service:
    - name: {{ service_name }}
    - ports:
      {%- for port in service.ports %}
      - {{ port }}
      {% endfor %}
    - require_in:
      - service: firewalld__service
    - require:
      - pkg: firewalld__pkg
    - watch_in:
        - firewalld__service
{%- endfor %}
{%- endif %}

{%- if firewalld.zones is defined and firewalld.zones is mapping %}
{%- for zone_name, zone in firewalld.zones.items()  %}
firewalld__{{ zone_name }}:
  firewalld.present:
    - name: {{ zone_name }}

{%- if zone.block_icmp is defined %}
    - block_icmp:
      {%- for icmp_type in zone.block_icmp  %}
      - {{ icmp_type }}
      {%- endfor %}
{%- endif %}

{%- if firewalld.services is defined and firewalld.services is mapping %}
    - services:
        {%- for service in firewalld.services  %}
        - {{ service }}
        {%- endfor %}
{%- endif %}

{%- if zone.ports is defined %}
    - ports:
      {%- for port in zone.ports %}
      - {{ port }}
      {% endfor %}
{%- endif %}

{%- if zone.rich_rules is defined %}
    - rich_rules:
      {%- for rule in zone.rich_rules %}
      - {{ rule }}
      {% endfor %}
{%- endif %}

    - prune_block_icmp: {{ salt['pillar.get']('zone.prune_block_icmp', True) }}
    - prune_ports: {{ salt['pillar.get']('zone.prune_ports', True) }}
    - prune_rich_rules: {{ salt['pillar.get']('zone.prune_rich_rules', True) }}
    - prune_services: {{ salt['pillar.get']('zone.prune_services', True) }}
    - require:
      - pkg: firewalld__pkg
    - watch_in:
        - service: {{ firewalld.service }}
{%- endfor %}
{%- endif %}
{%- endif %}