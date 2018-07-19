# Pillar data from orchestration state
{% set hostname = salt['pillar.get']('hostname', 'NO HOSTNAME') %}
{% set ip = salt['pillar.get']('ip', 'NO IP') %}
{% set valid_checksum = salt['pillar.get']('valid_checksum', 'NO CHECKSUM') %}
{% set password = salt['pillar.get']('password', 'NO PASSWORD') %}


##### JUST FOR TESTING - DELETE
{% set checksum = 'e95913d811c0fae6083eb709c356af73' %}
#####




### SHOW PILLAR DATA
show_output:
  test.configurable_test_state:
    - name: Show output
    - changes: True
    - result: True
    - comment: {{ hostname }} {{ ip }} {{ checksum }} {{ password }}

## Copy new firmware from Salt Master to switch
{% set scp_cmd = 'sshpass -p \'' + password + '\' scp /root/EOS-4.16.8FX-MLAGISSU-TWO-STEP.swi admin@' + ip + ':/mnt/flash' %}
show_cmd_{{ hostname }}:
  test.configurable_test_state:
    - name: version
    - changes: false
    - result: True
    - comment: "{{ scp_cmd }}"

# Install sshpass in the Salt Master
# REMOVE IF ALL SALT MASTERS HAVE SSHPASS INSTALLED ALREADY
install_sshpass:
  pkg.installed:
    - name: sshpass

### COPY FIRMWARE COMMAND
copy_firmware_{{ hostname }}:
  cmd.run:
    - name: "{{ scp_cmd }}"


## On the switch, verify that the copied firmware file has the correct checksum
{% set checksum_cmd = 'salt-ssh --roster-file=/etc/salt/roster-devices -r -i ' + hostname + ' "verify /md5 flash:EOS-4.16.8FX-MLAGISSU-TWO-STEP.swi" --out=json ' %}
{% set checksum_raw = salt['cmd.run'](checksum_cmd) %}
{% set checksum_json = checksum_raw | load_json  %}
{% set device= 'hostname' %}
{% set checksum = checksum_json[device].stdout.replace("Password: \nverify /md5 (flash:EOS-4.16.8FX-MLAGISSU-TWO-STEP.swi) = ", "") %}

show_checksum_{{ device }}:
  test.configurable_test_state:
    - name: checksum
    - changes: false
    - result: True
    - comment: "{{ checksum }}"

{% if checksum == valid_checksum %}
## Script continues when server checksum for the firmware equals the switch checksum for said file
checksum_correct:
  test.configurable_test_state:
    - name: checksum
    - changes: True
    - result: True
    - comment: CHECKSUM VALID - PROCEED TO RUN FIRMWARE UPGRADE
{% else %}
checksum_invalid:
  test.configurable_test_state:
    - name: checksum
    - changes: True
    - result: False
    - comment: CHECKSUM INVALID - CANCEL FIRMWARE UPGRADE
{% endif %}
