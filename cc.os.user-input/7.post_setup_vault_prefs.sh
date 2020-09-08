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

# // VAULT_TOKEN ought to exist by now from either init or copy from vault1:

if [[ ${VAULT_TOKEN} == "" ]] ; then VAULT_TOKEN=$(grep -F VAULT_TOKEN ${HOME_PATH}/.bashrc | cut -d'=' -f2) ; fi ;
if [[ ${VAULT_TOKEN} == "" ]] ; then pERR 'VAULT ERROR: No Token Found.\n' ; exit 1 ; fi ;

if [[ -s vault_token_perf1.json ]] ; then PR_TOKEN="$(jq -r '.wrap_info.token' vault_token_perf1.json)" ; fi ;
if [[ -s vault_token_perf2.json ]] ; then PR_TOKEN="$(jq -r '.wrap_info.token' vault_token_perf2.json)" ; fi ;
if [[ ${PR_TOKEN} == "" ]] ; then pERR 'VAULT ERROR: PERF Token NOT Found.\n' ; exit 1 ; fi ;

# vault write /sys/replication/dr/secondary/enable token=${DR_TOKEN} 2> /dev/null ;
vault write /sys/replication/performance/secondary/enable token="${PR_TOKEN}" 2> /dev/null ;
if (($? == 0)) ; then pOUT 'VAULT: PREF Replication Token Accepted.\n' ;
else pERR 'VAULT ERROR: Applying PREF Replication token.\n' ; fi ;

exit 0 ;

# // invoke manually to promote / demote:
# // MUST HAVE A VALID TOKEN for operational purposes before crash
VT=$(vault login -method=userpass username=root2 password=root -format=json 2>/dev/null | jq -r .auth.client_token) ;
VAULT_TOKEN=${VT} vault write /sys/replication/performance/secondary/promote
#vault write /sys/replication/performance/primary/demote
#vault write /sys/replication/performance/primary/disable
