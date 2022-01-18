# // logger
function pOUT() { printf "$1\n" ; } ;

# // Colourised logger for errors (red)
function pERR()
{
	# sMSG=${1/@('ERROR:')/"\e[31mERROR:\e[0m"} ; sMSG=${1/('ERROR:')/"\e[31mERROR:\e[0m"}
	if [[ $1 == "--"* ]] ; then pOUT "\e[31m$1\n\e[0m\n" ;
	else pOUT "\n\e[31m$1\n\e[0m\n" ; fi ;
}


VVERSION=$(vault --version) ;
if ! [[ ${VVERSION} == *"ent"* ]] ; then
	pERR "VAULT ENTERPRISE REQUIRED! - but found: ${VVERSION}\n" ; exit 1 ;
fi ;

if [[ ${VAULT_TOKEN} == "" ]] ; then
	# // VAULT_TOKEN ought to exist by now from either init or copy from vault1:
	VAULT_TOKEN=$(grep -F VAULT_TOKEN ${HOME_PATH}/.bashrc | cut -d'=' -f2) ;
fi ;

if [[ ${VAULT_TOKEN} == "" ]] ; then pERR 'VAULT ERROR: No Token Found.\n' ; exit 1 ; fi ;

# // enable Vault Audits.
VAULT_AUDIT_PATH='vaudit.log' ;
vault audit enable file file_path=${VAULT_AUDIT_PATH} > /dev/null ;
if (($? == 0)) ; then pOUT "VAULT: Audit logs enabled at: ${VAULT_AUDIT_PATH}\n" ;
else pERR 'VAULT ERROR: NOT ABLE TO ENABLE AUDITS.\n' ; fi ;

#vault write -f sys/replication/dr/primary/enable > /dev/null 2>&1 ;
vault write -f sys/replication/performance/primary/enable > /dev/null 2>&1 ;
if (($? == 0)) ; then pOUT 'VAULT: PR Successfully set "sys/replication/dr/primary/enable"\n' ;
else pERR 'VAULT ERROR: Setting "sys/replication/performance/primary/enable"\n' ; fi ;

#vault write sys/replication/dr/primary/secondary-token -format=json id=hsm2 2>/dev/null > vault_token_dr.json
vault write sys/replication/performance/primary/secondary-token -format=json id="DC2-PR-B" 2>/dev/null > vault_token_perf1.json
if (($? == 0)) ; then pOUT 'VAULT: PREF-1 Replication "vault_token_perf1.json" generated.\n' ;
else pERR 'VAULT ERROR: Generating PREF-1 Replication "vault_token_perf1.json"\n' ; fi ;

vault write sys/replication/performance/primary/secondary-token -format=json id="DC3-PR-C" 2>/dev/null > vault_token_perf2.json
if (($? == 0)) ; then pOUT 'VAULT: PREF-2 Replication "vault_token_perf2.json.\n' ;
else pERR 'VAULT ERROR: Generating PREF-2 Replication "vault_token_perf2.json"\n' ; fi ;

# // WONT DO FILTERING
# vault write sys/replication/performance/primary/paths-filter/secondary mode="deny" paths="EU_GDPR_data/, office_FR"

vault policy write superuser > /dev/null -<<EOF
path "*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
EOF
if (($? == 0)) ; then pOUT 'VAULT: POLICY superuser uploaded.\n' ;
else pERR 'VAULT ERROR: uploading superuser POLICY."\n' ; fi ;

vault auth enable userpass > /dev/null 2>&1 ;
if (($? == 0)) ; then pOUT 'VAULT: ENABLED UserPass.\n' ;
else pERR 'VAULT ERROR: UserPass could not be enabled."\n' ; fi ;

vault write auth/userpass/users/root2 password="root" policies="superuser" > /dev/null 2>&1 ;
if (($? == 0)) ; then pOUT 'VAULT: USER root2 created.\n' ;
else pERR 'VAULT ERROR: Unable to creat roo2."\n' ; fi ;

vault secrets enable pki > /dev/null 2>&1 ;
if (($? == 0)) ; then pOUT 'VAULT: PKI mount enabled at pki/.\n' ;
else pERR 'VAULT ERROR: Unable to enable PKI mount."\n' ; fi ;

vault write pki/root/generate/internal common_name='tas600 toyota-europe' ttl=960h > /dev/null 2>&1 ;
if (($? == 0)) ; then pOUT 'VAULT: pki/ CA configured.\n' ;
else pERR 'VAULT ERROR: Unable to configure PKI CA ."\n' ; fi ;

vault write pki/roles/tas600 allowed_domains=tas600.toyota-europe.com allow_subdomains=true max_ttl=961h > /dev/null 2>&1 ;
if (($? == 0)) ; then pOUT 'VAULT: PKI ROLE tas600 writen.\n' ;
else pERR 'VAULT ERROR: Unable to create PKI ROLE."\n' ; fi ;

vault write pki/issue/tas600 common_name=123.tas600.toyota-europe.com ttl=400h > /dev/null 2>&1 && \
vault write pki/issue/tas600 common_name=1234.tas600.toyota-europe.com ttl=400h > /dev/null 2>&1 && \
vault write pki/issue/tas600 common_name=12345.tas600.toyota-europe.com ttl=400h > /dev/null 2>&1 ;

if (($? == 0)) ; then pOUT 'VAULT: PKI Generated three (3) test certificates.\n' ;
else pERR 'VAULT ERROR: Unable to generate 3 PKI certificaets."\n' ; fi ;
