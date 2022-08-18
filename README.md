# HashiCorp **`vault`** Autopilot issues in 1.11.2

[![asciicast](https://asciinema.org/a/515656.svg)](https://asciinema.org/a/515656)

```bash
git clone git@github.com:aphorise/hashicorp.vagrant_vault-hsm_3cluster-pr.git
cd "!$:t:r";
git checkout raft/bugs-autopilot ;
cp ~/vault_license.txt vault_files/vault_license.txt ;
# // PUT LICENSE IN: vault_files/vault_license.txt

# // && SEE Vagrantfile to set L14 '5' - L15 & L16 '0' - L34 to match your net.
vagrant up ;
# // after 'hsm1-vault1' is ready open 2 separate terminals:

# // Terminal 1:
vagrant ssh hsm1-vault1 ;
# // vagrant@hsm1-vault1:~$ \
watch vault operator raft list-peers ;
# // Terminal 2:
vagrant ssh hsm1-vault1 ;
# // vagrant@hsm1-vault1:~$ \
jv ;  # // to follow vault logs

# // ------------------------------------------------------
# // 1ST ISSUE - after all is complete - do:
CMD='sudo service vault stop' ;
vagrant ssh hsm1-vault2 -- -t "$CMD" && vagrant ssh hsm1-vault3 -- -t "${CMD}" ;
# // NON-VOTER STATE DOES NOT UPDATE
  # Node           Address                 State       Voter
  # ----           -------                 -----       -----
  # hsm1-vault1    192.168.168.253:8201    leader      true
  # hsm1-vault2    192.168.168.252:8201    follower    true
  # hsm1-vault3    192.168.168.251:8201    follower    true
  # hsm1-vault4    192.168.168.250:8201    follower    true
  # hsm1-vault5    192.168.168.249:8201    follower    true
# // STEP-DOWN ON LEADER & FRESH OCCURS AS EXPECTED:
vagrant ssh hsm1-vault1 -- -t "vault operator step-down" ;
# // ------------------------------------------------------

# // ------------------------------------------------------
# // 2ND ISSUE - RESTART ANEW & after all is complete - do:
vagrant destroy -f hsm1-vault4 hsm1-vault5 ;  # // makes peer remove request.
vagrant ssh hsm1-vault3 -- -t "sudo service vault stop" ;
# // DROPS QUORUM to 3 from 1 - also marking last remaining node as non-voter
  # Node           Address                 State       Voter
  # ----           -------                 -----       -----
  # hsm1-vault1    192.168.168.253:8201    leader      true
  # hsm1-vault2    192.168.168.252:8201    follower    false
  # hsm1-vault3    192.168.168.251:8201    follower    false
# // ^^^ SHOULD BE 2 NODES VOTERS and QUORUM MIN SHOULD STAY 2
# // ---------------------------------------------------------
```

------
