# HashiCorp `vagrant` demo of **`vault`** HSM with Performance Replication Clusters.

This repo extends [**HSM**](https://www.vaultproject.io/docs/enterprise/hsm) mocked [setup (`vagrant_vault-hsm`)](https://github.com/aphorise/hashicorp.vagrant_vault-hsm) in the context of (PR) Performance Replication instead of (DR) Disaster Recovery that was previously done.


## Makeup & Concept
The first Vault node (`hsm1-vault1`) is that of a [Performance Replication (PR)](https://learn.hashicorp.com/vault/operations/ops-disaster-recovery) PR-Primary CLUSTER_A (`hsm1`) & a similar second Vault node (`hsm2-vault1`) is a PR-Secondary that's part of CLUSTER_B (`hsm2`) with CLUSTER_C (`hsm3`) in the same capacity as another PR-Secondary.

A depiction below shows the conceptional roles with & the network [connectivity and overall PRC, Gossip, UDP/TCP port](https://learn.hashicorp.com/vault/operations/ops-reference-architecture#network-connectivity-details) expected to be produced. After initial setups the PR Demotion & Promotion sets can be followed to mimic similar flows.

```
                                 VAULT CLUSTERS:
 VAULT STORE:                  ._________________.233
  - Raft (default)             |   hsm3-vault1   |
  - Consul (Vagrantfile)       | hsm auto-unseal | ... + others
                              ╱|_________________|╲
                             ╱(hsm3 - PR SECONDARY)╲
                            ╱           ▒           ╲
                           ╱            ▒            ╲
             .____________╱____.253     ▒        .____╲ _____________.243
             |   hsm1-vault1   |        ▒        |   hsm2-vault1   |
... + others | hsm auto-unseal |◄-------▒-------►| hsm auto-unseal | ... + others
             |_________________|        ▒        |_________________|
             (hsm1 - PR PRIMARY)        ▒       (hsm2 - PR SECONDARY)
                                     NETWORK
```


### Prerequisites
Ensure that you already have the following hardware & software requirements:
 
##### HARDWARE & SOFTWARE
 - **RAM** **3-6**+ Gb Free minimum more if using Consul (dont hit SWAP either or stay < 100Mb).
 - **CPU** **3-6**+ Cores Free minimum (2 or more per vm) more if using Consul.
 - **Network** interface allowing IP assignment and interconnection in VirtualBox bridged mode for all instances.
   - adjust `sNET='en0: Wi-Fi (Wireless)'` in **`Vagrantfile`** to match your system.
 - [**Virtualbox**](https://www.virtualbox.org/) with [Virtualbox Guest Additions (VBox GA)](https://download.virtualbox.org/virtualbox/) & [**Vagrant**](https://www.vagrantup.com/) correctly installed.
 - **Few** (**2**) **`shell`** or **`screen`** sessions to allow for multiple SSH sessions.
 - :lock: **IMPORTANT**: An [**enterprise license**](https://www.hashicorp.com/products/vault/pricing/) is **needed** for both [HSM Support](https://www.vaultproject.io/docs/enterprise/hsm) as well as [Performance Replication](https://www.vaultproject.io/docs/enterprise/replication/) features. **BY DEFAULT**: **not setting** a valid license (in `vault_license.txt`) is possible for **trail / evaluation purposes only** with a limit of **29 minutes** per node (warning messages should be apparent throughout before auto-sealing after). :lock:


## Usage & Workflow
Refer to the contents of **`Vagrantfile`** for complete details of Clusters A, B & C.

Other auto-unseal types can be attempted by adjusting: **`vault_files/vault_seal.hcl`** & valid license keys can be set in: **`vault_files/vault_license.txt`** .

```bash
vagrant up --provider virtualbox ;
# // … output of provisioning steps.

vagrant global-status ; # should show running nodes
  # id       name         provider    state    directory
  # ----------------------------------------------------------------------------------------------
  # 6c90677  hsm1-vault1  virtualbox  running  /home/auser/hashicorp.vagrant_vault-hsm_3cluster-pr
  # 17c0c0d  hsm2-vault1  virtualbox  running  /home/auser/hashicorp.vagrant_vault-hsm_3cluster-pr
  # cf1034a  hsm3-vault1  virtualbox  running  /home/auser/hashicorp.vagrant_vault-hsm_3cluster-pr


vagrant ssh hsm2-vault1 ;  # // On a separate Terminal promote vault2.
  # ………
#vagrant@hsm2-vault1:~$ \
vault status ;
  # ………
vault read sys/replication/status -format=json | jq ;
vault read sys/replication/performance/status -format=json | jq ;

# // IMPORTANT - we need a (TTL) valid operational token to be able to perform promotion. 
#vagrant@hsm2-vault1:~$ \
cat post_setup_vault.sh ;
  # ………
  # VT=$(vault login -method=userpass username=root2 password=root -format=json 2>/dev/null | jq -r .auth.client_token) ;
  # VAULT_TOKEN=${VT} vault write /sys/replication/performance/secondary/promote
  # ………

#vagrant@hsm2-vault1:~$ \
VAULT_TOKEN=$(vault login -method=userpass username=root2 password=root -format=json 2>/dev/null | jq -r .auth.client_token) ;
vault status ;
vault write -f /sys/replication/performance/secondary/promote ;
vault read sys/replication/status -format=json | jq ;
vault read sys/replication/performance/status -format=json | jq ;
exit ;


vagrant ssh hsm1-vault1 ;  # // On a separate Terminal session demote vault1.
  # ………
#vagrant@hsm1-vault1:~$ \
vault status ;
vault read sys/replication/status -format=json | jq ;
vault read sys/replication/performance/status -format=json | jq ;
vault write -f /sys/replication/performance/primary/demote ;
vault status ;
vault read sys/replication/status -format=json | jq ;
vault read sys/replication/performance/status -format=json | jq ;

# // A is still primary so stop or re-enable replication as secondary of B now.
# // PR C is still relative A & needs to be redone relative to B the same as A. 
# // ………
# // ………

# // ---------------------------------------------------------------------------
# when completely done:
vagrant destroy -f hsm1-vault1 hsm2-vault1 hsm3-vault1 ; # ... destroy all - ORDER IMPORTANT
vagrant box remove -f debian/buster64 --provider virtualbox ; # ... delete box images
```


## Referenced Literature:
This is intended as a mere practise / training exercise.

See also:
 - [github.com/aphorise/hashicorp.vagrant_vault-hsm ](https://github.com/aphorise/hashicorp.vagrant_vault-hsm)
 - [Vault Learn: Setting up Performance Replication](https://learn.hashicorp.com/tutorials/vault/performance-replication)
 - [Vault Learn: HSM Integration - Seal Wrap](https://learn.hashicorp.com/vault/security/ops-seal-wrap)
 - [Vault Learn: HSM Integration - Entropy Augmentation](https://learn.hashicorp.com/vault/security/hsm-entropy)
 - [Vault API: `/sys/sealwrap/rewrap`](https://www.vaultproject.io/api-docs/system/sealwrap-rewrap)
 - [Vault DOC: Vault Enterprise HSM Support](https://www.vaultproject.io/docs/enterprise/hsm)

------
