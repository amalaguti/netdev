# Pillar data from orchestration state
{% set hostname = salt['pillar.get']('hostname', 'NO HOSTNAME') %}

# Known higher versions - DONT NEED UPGRADE
{% set higher_versions = ['4.12.10', '4.21.A2', '5.0.0'] %}

# Known lower versions - MUST BE UPGRADED
{% set lower_versions = ['3.00.2D', '4.00.2D', '4.10.2B'] %}
# UNKNOWN VERSIONS MUST THROW FAILURE (Procedure not checked)


##### JUST FOR TESTING - DELETE
{% set version = '3.00.2D' %}
#####


# TODAY IS THURSDAY # YEAH!! Hell yeah!!

### JUST TO SHOW RECEIVED PILLAR DATA
show_output:
  test.configurable_test_state:
    - name: Show output
    - changes: True
    - result: True
    - comment: {{ hostname }}

## run "show version" on the switch, parse it through hella regex, it comes out on the backside as "4.12.10"

{% set version_cmd = 'salt-ssh --roster-file=/etc/salt/roster-devices -r -i ' + hostname + ' "show version | i image" --out=json ' %}
{# {% set version_raw = salt['cmd.run'](version_cmd) %}#}
{# {% set version_json = version_raw | load_json  %}#}
{% set device = hostname %}
{# {% set version = version_json[device].stdout.replace('Password: \nSoftware image version: ', "") %} #}

show_version_cmd_{{ device }}:
  test.configurable_test_state:
    - name: version
    - changes: True
    - result: True
    - comment: |
{#        {{ version_cmd }} #}
        {{ version  }}


{% if version not in higher_versions and version not in lower_versions %}
inform_unknown_version:
  test.configurable_test_state:
    - name: version
    - changes: True
    - result: False
    - comment: VERSION UNKNOWN - RETURNING FALSE TO AVOID UPGRADE
{% elif version in higher_versions %}
inform_higher_version:
  test.configurable_test_state:
    - name: version
    - changes: True
    - result: False
    - comment: KNOWN HIGHER VERSION - RETURNING FALSE TO AVOID UPGRADE
{% else %}
inform_lower_version:
  test.configurable_test_state:
    - name: version
    - changes: True
    - result: True
    - comment: KNOWN LOWER VERSION - RETURNING TRUE TO UPGRADE
{% endif %}
