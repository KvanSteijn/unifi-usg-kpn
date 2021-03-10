#!/bin/vbash

source /opt/vyatta/etc/functions/script-template

# Default value
telegram_token=""
to_use_id=""

# Telegram settings
telegram_url='https://api.telegram.org/bot'$telegram_token
telegram_msg_url=$telegram_url'/sendMessage'

# Other settings
r_status="1"

# Function to encode url
telegram_urlencode() {
    echo "$*" | sed 's:%:%25:g;s: :%20:g;s:<:%3C:g;s:>:%3E:g;s:#:%23:g;s:{:%7B:g;s:}:%7D:g;s:|:%7C:g;s:\\:%5C:g;s:\^:%5E:g;s:~:%7E:g;s:\[:%5B:g;s:\]:%5D:g;s:`:%60:g;s:;:%3B:g;s:/:%2F:g;s:?:%3F:g;s^:^%3A^g;s:@:%40:g;s:=:%3D:g;s:&:%26:g;s:\$:%24:g;s:\!:%21:g;s:\*:%2A:g'
}

# Function to send messages
telegram_send() {
    # Send only telegram messages when we have valid settings
    if [[ $telegram_token != "" && $to_use_id != "" ]]; then
        # Handle parse mode
        case "$1" in
            markdown*)
                # Get text from third param
                text="$2"
                until [ $(echo -n "$text" | wc -m) -eq 0 ]; do
                    res=$(curl -s "$telegram_msg_url" -d "chat_id=$to_use_id" -d "text=$(telegram_urlencode "${text:0:4096}")" -d "parse_mode=markdown" -d "disable_web_page_preview=true")
                    text="${text:4096}"
                done
            ;;

            *)
                # No parsemode given, use $1 as text
                text="$1"
                until [ $(echo -n "$text" | wc -m) -eq 0 ]; do
                    res=$(curl -s "$telegram_msg_url" -d "chat_id=$to_use_id" -d "text=$(telegram_urlencode "${text:0:4096}")")
                    text="${text:4096}"
                done
            ;;
        esac
    fi
}

# Check if IGMP proxy is running
r_ps=$(ps aux | grep -v grep);
if echo "$r_ps" | grep -q "igmpproxy"; then
    # IGMP proxy is running
    :
else
    # Send message
    telegram_send "USG-PRO: IGMP proxy is not running, try to start IGMP proxy!"

    # Try to restart IGMP proxy
    sudo /opt/vyatta/sbin/config-igmpproxy.pl --action=restart
    if [ $? -eq 0 ]; then
        r_second_ps=$(ps aux | grep -v grep);
        if echo "$r_second_ps" | grep -q "igmpproxy"; then
            telegram_send "USG-PRO: IGMP proxy is started"
        else
            telegram_send "USG-PRO: Failed to start IGMP proxy"
            r_status="0"
        fi
    else
        telegram_send "USG-PRO: Failed to start IGMP proxy"
        r_status="0"
    fi
fi

# Start configure
configure

# Check if IGMP proxy interface exists
r_igmp=$(show protocols igmp-proxy interface);
if echo "$r_igmp" | grep -q "empty"; then
    telegram_send "USG-PRO: IGMP proxy interface not exists!"
    r_status="0"
fi

# Do only the nexts steps when everything is good
if [[ $r_status == "1" ]]; then
    # Try to get DHCP IP */
    r_ip=$(run show dhcp client leases | grep router | awk '{ print $3 }');
    iptv_static=$(echo "set protocols static route 213.75.112.0/21 next-hop $r_ip");
    if [[ $r_ip != "" ]]; then
        # Get old IP and check if the IP is different than the old one
        r_old_ip=$(show protocols static route 213.75.112.0/21 next-hop | awk '{ print $2 }' | tr -d '\n');
        if [[ $r_old_ip != $r_ip ]]; then
            # Delete old IP
            delete protocols static route 213.75.112.0/21

            # Set new IP
            eval $iptv_static

            # Commit and save last changes
            commit
            save
            
            # Restart IGMP proxy
            sudo /opt/vyatta/sbin/config-igmpproxy.pl --action=restart

            # Send message
            telegram_send "USG-PRO: Static route is changed: $r_ip"
        fi
    fi
fi

# Close configure
exit
