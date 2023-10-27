#!/bin/bash

echo "Automating GoDaddy TXT Record creation for $CERTBOT_DOMAIN"

# Strip only the top domain to get the zone id
DOMAIN=$(expr match "$CERTBOT_DOMAIN" '.*\.\(.*\..*\)')
SUBDOMAIN=$(expr match "$CERTBOT_DOMAIN" '\(.*\)\..*\..*')

# If we didn't match above, is our domain simply a primary domain?
[[ -z "$DOMAIN" ]] && DOMAIN=$(expr match "$CERTBOT_DOMAIN" '\(.*\..*\)')

# If wildcard over primary domain, clear out SUBDOMAIN.
[[ "$SUBDOMAIN" == "*" ]] && SUBDOMAIN=""

# If wildcard over subdomain, strip leading *.
[[ ( -n "$SUBDOMAIN" ) && ( $(expr match "$SUBDOMAIN" '\*\..*') > 0 ) ]] && SUBDOMAIN=$(expr match "$SUBDOMAIN" '\*\.\(.*\)')

echo "Parsed domain=$DOMAIN, subdomain=$SUBDOMAIN"

# Create TXT record
[[ -n "$SUBDOMAIN" ]] && TXT_RECORD_NAME="_acme-challenge.$SUBDOMAIN" || TXT_RECORD_NAME="_acme-challenge"

# Minimum TTL is 600 seconds, so use that.
echo "Updating GoDaddy DNS: Domain=$DOMAIN, TxtRecordName=$TXT_RECORD_NAME, TxtRecordValue=$CERTBOT_VALIDATION, TTL=600"

# Save the http status to evaluate success
if [[ "$TESTONLY" != "test" ]]
then
STATUS=$(curl -w '%{http_code}' -X PUT "https://api.godaddy.com/v1/domains/$DOMAIN/records/TXT/$TXT_RECORD_NAME" \
-H "Accept: application/json" -H "Content-Type: application/json" \
-H "Authorization: sso-key $API_KEY:$API_SECRET" \
-d '[{ "data": "'"$CERTBOT_VALIDATION"'", "ttl": 600 }]')

echo "DNS update returned HTTP Status: $STATUS"
else
echo "Testing only. If Live, we would call the following Domains API endpoint: PUT https://api.godaddy.com/v1/domains/$DOMAIN/records/TXT/$TXT_RECORD_NAME"
fi
