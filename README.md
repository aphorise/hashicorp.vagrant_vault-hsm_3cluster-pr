# HashiCorp `vagrant` demo of **`vault`** **1.9.2** PKI viewing issue in Performance-Secondary Clusters.

## Usage & Workflow

```bash
# // SET LICENSE IN vault_files/vault_license.txt
echo '...' > vault_files/vault_license.txt

# // ADJUST sNET for local network adapter & `sCLUSTERA_IP_CLASS_D` &
# // `sCLUSTERB_IP_CLASS_D` for your network.

vagrant up --provider virtualbox ;
# // … output of provisioning steps.

vagrant ssh hsm2-vault1 ;  # // On a separate Terminal ssh to vault2.
  # ………
#vagrant@hsm2-vault1:~$ \
VAULT_TOKEN=$(vault login -method=userpass username=root2 password=root -format=json 2>/dev/null | jq -r .auth.client_token) ;

# // CONTINUE via UI under Secrets to observe 404 issue or otherwise:
curl -v -X LIST -H "X-Vault-Token: ${VAULT_TOKEN}" ${VAULT_ADDR}/v1/pki/certs
  # > LIST /v1/pki/certs HTTP/1.1
  # > Host: 192.168.178.243:8200
  # > User-Agent: curl/7.64.0
  # > Accept: */*
  # > X-Vault-Token: s.ZjoFirq7hmGAJN53Z0wvxf55
  # >
  # < HTTP/1.1 404 Not Found
  # < Cache-Control: no-store
  # < Content-Type: application/json
  # < Date: Tue, 18 Jan 2022 15:50:53 GMT
  # < Content-Length: 14
  # <
  # {"errors":[]}

# // GENERATE NEW CERT ON PR-SECONDARY NO ISSUE - yet still cant list.
```

------
