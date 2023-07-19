# Ansible Role thbe-sap

[![Molecule](https://github.com/thbe/ansible-role-sap/actions/workflows/molecule.yml/badge.svg)](https://github.com/thbe/ansible-role-sap/actions/workflows/molecule.yml)

This role provides the basic settings, packages, tweaks and so on and so forth to operate an SAP system.

## Requirements

This role does not have any requirements.

## Role Variables

* **role_directory** - This variable contains the root path of the directories used by thbe roles (**do not change!**)
* **sap_role_name** - Set SAP role name (default: not defined)
* **sap_profile** - Set SAP profile (default: not defined)
* **sap_firewall** - Enable SAP specific firewall rules (default: none)
* **sap_alias** - Set SAP alias hostname (default: not defined)
* **sap_motd** - Enable Message of the Day (default: false)
* **sap_ha** - Enable Pacemaker cluster (default: false)
* **sap_ha_stonith** - Enable Pacemaker stonith device (default: true)
* **sap_anf** - Enable Azure Netapp (default: false)
* **sap_dr** - Enable SAP Disaster Recovery (default: false)
* **sap_router** - Enable SAP Router (default: false)
* **sap_router_manage** - Manage saproutetab (default: false)
* **rhn_organization_id** - Organizational ID to register at RHN (default: 'unset')
* **rhn_activation_key** - activation key to register at RHN (default: 'unset')
* **rhn_pool_id** - Pool ID to be consumed (default: 'unset')
* **rhn_repo_eus** - Enable EUS repositories (default: false)
* **rhn_repo_e4s** - Enable E4S repositories (default: false)
* **rhel_repos_8_sap** - List of RHEL SAP repositories
* **rhel_repos_9_sap** - List of RHEL SAP repositories
* **sap_packages_requirement** - List of SAP required packages
* **sap_packages_compatibility** - List of SAP compatibility packages

## Dependencies

This role depends on:

* thbe.common
* thbe.rhel

## Example Playbook

This role can be included in the site.yml like this:

```yaml
# Site playbook
- name: Ansible playbooks for all nodes
  hosts: all
  collections:
    - ansible.posix
    - community.general
  gather_facts: true
  tasks:
    - name: Role Common (DevOps preparation)
      ansible.builtin.include_role:
        name: thbe.common
    - name: Role rhel
      ansible.builtin.include_role:
        name: thbe.rhel
    - name: Role SAP
      ansible.builtin.include_role:
        name: thbe.sap
```

## License

GPL-3.0-only

## Author Information

Thomas Bendler - [https://www.thbe.org/](https://www.thbe.org/)
