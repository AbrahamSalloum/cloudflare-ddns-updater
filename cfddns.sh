#!/bin/bash

# cf email 
email="mail@account.com"

# semi-colon (;) delimted values of subdomain;zone;key 
records=("sub.domain.com;domain.com;bf1e5FAKEFKEKAKE4234324d5" "sub.example.com;example.com;cdfsfsdfs5FAKEFKEKAKE4234324d5")
#

for record in "${records[@]}"
do

for opt in "$@"; do
	case $opt in 
	--log)
		log=1
		;;
	--force)
		force=1
		;;
	esac
done 


domain=$(echo $record | cut -d ";" -f 1)
zone=$(echo $record | cut -d ";" -f 2)
key=$(echo $record | cut -d ";" -f 3)

ipaddr=$(dig @1.1.1.1 ch txt whoami.Cloudflare +short | awk -F'"' '{ print $2}')
cfarec=$(dig @1.1.1.1 $domain +short)



if [ "$force" != 1 ]; then
	if [ "$ipaddr" == "$cfarec" ]; then 
		echo "IP $ipaddr for $domain unchanged"
		updateid=0
	else
		updateip=1
	fi
else
	echo "forcing IP update to: $ipaddr"
	updateip=1
fi

if [ "$updateip" == 1 ]; then
	zidreq=$(curl -sS "https://api.cloudflare.com/client/v4/zones?name=$zone" \
		-H "X-Auth-Email: $email" \
		-H "X-Auth-Key: $key" \
		-H "Content-Type: application/json")
	
	zid=$(echo $zidreq | grep -Po '(?<="id":")[^"]*' | head -1)
	
	ridreq=$(curl -sSX GET "https://api.cloudflare.com/client/v4/zones/$zid/dns_records?name=$domain" \
		-H "X-Auth-Email: $email" \
		-H "X-Auth-Key: $key" \
		-H "Content-Type: application/json") 
	rid=$(echo $ridreq | grep -Po '(?<="id":")[^"]*')
	
	update=$(curl -sSX PUT "https://api.cloudflare.com/client/v4/zones/$zid/dns_records/$rid" \
     	-H "X-Auth-Email: $email" \
     	-H "X-Auth-Key: $key" \
     	-H "Content-Type: application/json" \
     	--data '{"type":"A","name":"'${domain}'","content":"'${ipaddr}'","ttl":120,"proxied":false}')
fi

if [ "$log" == 1 ]; then
	printf "Current IP for $domain is: $cfarec\n" | tee -a ~/log-cfddns
	printf "Current public IP is: $ipaddr\n\n" | tee -a ~/log-cfddns
	if [ "$updateip" == 1 ]; then 
		printf "$zidreq\n\n" >> ~/log-cfddns
		printf "$ridreq\n\n" >> ~/log-cfddns
		printf "$update" | tee -a ~/log-cfddns
	else
		printf "IP has not changed, no requests made to cloudflare\n\n" >> ~/log-cfddns
	fi
	printf "\n\nSee file: ~/log-cfddns for details\n\n" 
	exit 0
fi

printf "$update \n"
done
exit 0
