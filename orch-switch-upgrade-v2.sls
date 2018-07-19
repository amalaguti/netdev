# YOUR SALT-MASTER MINION ID
{% set saltmaster = 'salt' %}
# FIRMWARE CHECKSUM
{% set valid_checksum = 'e95913d811c0fae6083eb709c356af73' %}
# CONNECTION PASSWORD
{% set password = 'PASSWORD' %}


{% import_yaml 'netdev/my_devices.yaml' as my_devices %}
show_output:
  test.configurable_test_state:
    - name: Show devices
    - changes: False
    - result: True
    - comment: "{{ my_devices.devices }}"

## Creating the roster file
{% set M = my_devices['devices'] %}
{% for mm in M %}
show_info_{{ loop.index }}:
  test.configurable_test_state:
    - name: Show devices hostname
    - changes: False
    - result: True
    - comment: |
        "{{ mm }}"
        ip: {{ mm['host'] }}
        target: {{ mm['hostname'] }}


append_new_system-{{ loop.index }}:
  file.append:
    - name: /etc/salt/roster-devices
    - source: salt://netdev/roster_template.yaml
    - template: jinja
    - context:
        ip: {{ mm['host'] }}
        target: {{ mm['hostname'] }}
    - failhard: True

####
#### CHECK VERSION - STEP 1
####

# STATE TO CHECK VERSION ON BOTH DEVICES
# RUN ON SALT-MASTER
# PASS PILLAR hostname
# IF VERSION IS MINOR TO REQUIRED (ADD LOGIC IN THE STATE) THEN UPGRADE
1-check-min-version-{{ loop.index }}:
  salt.state:
    - tgt: {{ saltmaster }}
    - sls:
      - netdev.1-check-min-version
    - pillar:
        hostname: {{ mm['hostname'] }}

# EXECUTE NOTICATION IF CHECK VERSION FAILED
# DUE VERSION IS KNOWN AND HIGHER
# DUE VERSION IS UNKNOWN
1-inform-check-min-version-{{ loop.index }}:
  test.configurable_test_state:
    - name: INFO CHECK 1
    - changes: False
    - result: False
    - comment: 1-check-min-version HAS FAILED
    - onfail:
      - salt: 1-check-min-version-{{ loop.index }}
    - failhard: True


####
#### CHECK VERSION SUCCEEDED - CONTINUE TO NEXT STEP
####


####
#### COPY NEW FIRMWARE - STEP 2
####

# STATE TO COPY FIRMWARE TO BOTH DEVICES
# RUN ON SALT-MASTER
# PASS PILAR hostname and ip
# IF FIRMWARE CHECKSUM IS NOT VALID UPGRADE MUST BE CANCELLED
2-copy-firmware-{{ loop.index }}:
  salt.state:
    - tgt: {{ saltmaster }}
    - sls:
      - netdev.2-copy-firmware
    - pillar:
        hostname: {{ mm['hostname'] }}
        ip: {{ mm['host'] }}
        valid_checksum: {{ valid_checksum }}
        password: {{ password }}

# EXECUTE NOTICATION IF CHECKSUM OF COPIED FIRMWARE FAILED
2-inform-invalid_firmware-{{ loop.index }}:
  test.configurable_test_state:
    - name: INFO CHECKSUM
    - changes: False
    - result: False
    - comment: 2-checksum HAS FAILED
    - onfail:
      - salt: 2-copy-firmware-{{ loop.index }}
    - failhard: True

####
#### CHECKSUM VALID - CONTINUE TO NEXT STEP
####

{% endfor %}

####
#### RUN FIRMWARE UPGRADE - STEP 3
####

# STATE TO RUN FIRMWARE UPGRADE IN THE FIRST DEVICE
# RUN ON SALT-MASTER
# PASS PILAR hostname
3-upgrade-firmware-{{ M[0]['hostname'] }}:
  salt.state:
    - tgt: {{ saltmaster }}
    - sls:
      - netdev.3-upgrade-firmware
    - pillar:
        hostname: {{ M[0]['hostname'] }}

# EXECUTE NOTICATION IF FIRMWARE UPGRADE FAILED
3-inform-upgrade-firmware-failed-{{ M[0]['hostname'] }}:
  test.configurable_test_state:
    - name: INFO UPGRADE FIRMWARE
    - changes: False
    - result: False
    - comment: 3-upgrade firmware HAS FAILED
    - onfail:
      - salt: 3-upgrade-firmware-{{ M[0]['hostname'] }}
    - failhard: True
