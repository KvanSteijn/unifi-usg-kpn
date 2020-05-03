#!/bin/vbash

source /opt/vyatta/etc/functions/script-template

# Start configure
configure

# Try to get DHCP IP */
r_ip=$(run show dhcp client leases | grep router | awk '{ print $3 }');
iptv_static=$(echo "set protocols static route 213.75.112.0/21 next-hop $r_ip")
if [[ $r_ip != '' ]]; then
    # Delete old IP
    delete protocols static route 213.75.112.0/21

    # Set new IP
    eval $iptv_static

    # Commit and save last changes
    commit
    save
fi

# Close configure
exit
