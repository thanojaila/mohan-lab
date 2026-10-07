#!/usr/bin/env bash
#
# enable-https.sh - get a free HTTPS certificate and turn on https://
#
# Run ON THE SERVER, but ONLY AFTER the DNS record for the domain points
# at this server (otherwise the certificate request will fail).
#
#   ~/mohan-lab/scripts/enable-https.sh you@uh.edu
#
# The email address is used by Let's Encrypt for expiry warnings.
# Certificates renew automatically; nothing else to do afterwards.

set -euo pipefail

DOMAIN="${DOMAIN:-mohanlab.bme.uh.edu}"
EMAIL="${1:-}"

if [ -z "$EMAIL" ]; then
  echo "Usage: $0 you@uh.edu"
  exit 1
fi

MY_IP="$(curl -fsS https://checkip.amazonaws.com | tr -d '[:space:]')"
DNS_IP="$(getent ahostsv4 "$DOMAIN" | awk 'NR==1{print $1}' || true)"

echo "This server's public IP : $MY_IP"
echo "$DOMAIN currently points to : ${DNS_IP:-<nothing yet>}"

if [ "$DNS_IP" != "$MY_IP" ]; then
  echo
  echo "DNS does not point at this server yet, so HTTPS cannot be set up."
  echo "Ask UH IT to create an A record:  $DOMAIN  ->  $MY_IP"
  echo "DNS changes can take from a few minutes to a few hours. Try again later."
  exit 1
fi

sudo DEBIAN_FRONTEND=noninteractive apt-get install -y certbot python3-certbot-nginx
sudo certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos -m "$EMAIL" --redirect

echo
echo "HTTPS is on. Test: https://$DOMAIN"
echo "Automatic renewal check:"
sudo certbot renew --dry-run
