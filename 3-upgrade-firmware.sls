# Pillar data from orchestration state
{% set hostname = salt['pillar.get']('hostname', 'NO HOSTNAME') %}


### JUST TO SHOW RECEIVED PILLAR DATA
show_output:
  test.configurable_test_state:
    - name: Show output
    - changes: True
    - result: True
    - comment: {{ hostname }}
    ## TESTING GIT

## Run the change_boot alias command that is already on the Arista switch
{% set alias_cmd = 'salt-ssh --roster-file=/etc/salt/roster-devices -r -i ' + hostname + ' "change_boot" --out=json' %}
{# {% set alias_raw = salt['cmd.run'](alias_cmd) %} #}
{# {% set alias_json = alias_raw | load_json  %} #}
alias_cmd_{{ hostname }}:
  test.configurable_test_state:
    - name: alias
    - changes: false
    - result: True
{#    - comment: "{{ alias_json }}" #}
    - comment: |
        "{{ alias_cmd }}"
        'THIS SHOULD BE THE OUTPUT OF THE FIRMWARE EXECUTION, MAYBE WE DO NOT NEED TO CONVERT TO JSON'
        'FIND WAY TO PARSE THE OUTPUT'
# The output must be modified
# -- adrian --
