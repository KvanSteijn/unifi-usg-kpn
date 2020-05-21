# Ubiquity Unifi Security Gateway Pro 4 (USG‑PRO‑4) Configuration for KPN

## Introduction
My configuration is based on this repository: https://github.com/basmeerman/unifi-usg-kpn. The repository was not suitable enough for Unifi Security Gateway Pro 4 (USG‑PRO‑4). At home I have KPN as provider for Internet, IPTV and Voip services. The services are provided through fiber (FTTH). I recently tossed and sold all disperse hardware and bought Ubiquiti gear to upgrade, speedup and simplify my home network.
This guide provides the information and guidance needed to configure the Ubiquiti Unifi Security Gateway (https://www.ubnt.com/unifi-routing/usg/) to support both Internet and IPTV.

There are a lot of useful posts out there, this one is a composition of those articles and seems to work. See "Background reading / alternative sources".

## Design considerations
* **Simplicity**: I'd like my network to be as simple as possible, in hardware, software and configuration.
* **Forward compatibility**: Keep as much configuration in the USG configured as per controller to increase and maintain forward compatibility with upgrades. The USG comes with a default firewall configuration and routing options that allow you for guest network isolation etc. I'd like to adopt future advancements.
* **Automated updates**: Automate the updates of the routing as the IPTV network changes.

## Global design after the installation
```
        fiber
          |
    +----------+
    | FTTH NTU |
    +----------+
          |
      VLAN4 - iptv
      VLAN6 - internet
      VLAN7 - voip (not used in this setup)
          |
     +-----------+
     | USG‑PRO‑4 |   - Ubiquity Unifi Security Gateway Pro 4
     +-----------+
          |
         LAN2
          |
      +--------+
      | Switch |   - Ubiquity Unify Managed Switch
      +--------+
       |  |  |
       |  |  +-----------------------------+
       |  |                                |
       |  +-----------------+              |
       |                    |              |
+--------------+       +---------+      +-------+
| IPTV Decoder |       | Wifi AP |      | Other |
+--------------+       +---------+      +-------+
  - KPN IPTV
  - Netflix
```

## Hardware
* [Ubiquity Unifi Security Gateway](https://www.ui.com/unifi-routing/unifi-security-gateway-pro-4/) - Enterprise Gateway Router with Gigabit Ethernet - model: USG‑PRO‑4
* [Ubiquity Unifi Controller](https://www.ubnt.com/software/) - Centralized management software for the Ubiquity Unifi family.

## Further notes:
* Voip services are excluded in this configuration (I'm not using them). Read the links below if you're interested in setting this up. Basically you'll bridge VLAN 7 to USG LAN2 and connect the Experiabox.
* Configuration is **focused** on IPV4.
* This configuration guide references commands to be issued on multiple devices **USG** or the **Unifi Controller**. Always make sure you're connected to the right device.
* When connected to **USG**, you're connected to EdgeOS. Double pressing *tab* will give you an overview of commands.

## Prerequisites
1. To support routed IPTV make sure you're using a (managed) switch supporting IGMP snooping
2. Have a Ubiquity Unifi Controller running **internaly** (Controller in the "cloud" can break USG‑PRO‑4 configuration).
4. Configure you're internal LAN setup (IP range(s) / DHCP / AP's / etc.).
5. Connect the USG WAN port (eth0) to the FTTP NTU of KPN.
6. Connect the USG LAN1 port (eth1) to the Managed Switch.
7. Connect the USG LAN3/WAN2 port (eth3) to the Managed Switch.

## Steps

### 1. Setup basic Internet
1. Connect your PC to LAN1 port (eth1) on the USG‑PRO‑4.
2. Browse to 192.168.1.1.
3. Login with username: `ubnt` and password: `ubnt`
4. Click on `configuration`
5. Select by connection TypeType: `pppoe`
6. Set the username to: Past the MAC address AND replace the semicolons (":") with dashes ("-") AND postfix it with `@internet`. The format should look like: `xx-xx-xx-xx-xx-xx@internet`.
7. Set the password to: `kpn`
8. Check the checkbox `VLAN`, enter the value `6`
7. Click on the button: `Apply changes`.

All done, you should now have Internet in your LAN.

### 2. Auto update IPTV route automatically
The routed IP network sometimes changes, therefore the next-hop settings for routing should periodically change

1. Pull the `update_iptv_route.sh` from the repo
2. `SFTP` into the **USG**
3. Push the update script: `push update_iptv_route.sh`
4. `SSH` into the **USG**
5. Move the file: `mv update_iptv_route.sh /config/scripts/post-config.d/`
6. Make the file executable `chmod +x /config/scripts/post-config.d/update_iptv_route.sh`

### 3. Adopt Ubiquity Unifi Security Gateway Pro 4
1. `SSH` into the **USG**
2. Run this command with your **own** local Unifi Controller IP address: `set-inform http://{IP_ADRESS}:8080/inform`
3. Adopt Unifi Security Gateway Pro 4 in your controller.

### 4. Change port configuration on Ubiquity Unifi Security Gateway Pro 4
1. Go to `Devices` in **Unifi Controller** and click on your USG‑PRO‑4 model.
2. Go to `Ports` and active edit mode by clicking on the `Configure Interfaces` button. 
3. Disable all `LAN` ports.
4. Select by `Port WAN2 Network` for current LAN.
12. Click on the button `Apply`.
13. When you have `connected` status on your controller, you can disconnect the USG LAN1 port (eth1) with the Managed Switch.

### 6. Create `config.gateway.json` file  
The USG runs linux (EdgeOS version) as it's OS. The advanced settings need you to use the extension hooks Ubiquity build into the USG. See https://help.ubnt.com/hc/en-us/articles/215458888-UniFi-How-to-further-customize-USG-configuration-with-config-gateway-json for more information.

_At the time of writing the article is not 100% correct, the configuration in the custom configuration file is merged with the system configuration in the way that non-existent settings are added and existing items are overwritten by the settings in the file. Take good care not to mix and overwrite critical security settings with the config file. For this reason the config file provided in this repo is a minimum set of settings, all other settings are preserved (and hence future changes in upgrades as well)._

Notes:
* Basically you'll need to create and upload an JSON file named: `config.gateway.json` into a specific folder of the Unifi Controller filesystem and then force the provisioning from the controller to the USG.
* The custom configuration file references firewall rules that are not within the configuration file, those are registered and provided by Ubiquity in the standard configuration of the USG.

For finding the correct location to place `config.gateway.json` on the USG, see: https://help.ubnt.com/hc/en-us/articles/215458888-UniFi-How-to-further-customize-USG-configuration-with-config-gateway-json.

Let's get started.

Pull the `config.gateway.json` from the repo and change the following:
1. Replace the MAC address placeholder `xx-xx-xx-xx-xx-xx` with the real MAC address of the USG (see *Setup basic Internet, step 6*).
2. Adjust the IP ranges / DHCP ranges to you're liking (currently `192.168.1.1/24` on this tutorial) but they can be any range as long as they do not overlap public IP spaces (duh) and the IPTV ranges KPN uses.
3. Save the file (using UNIX file format)
4. (optional) Use an online JSON validator to check of you have created / not corrupted the JSON file.
6. In case the Controller has an **SSH deamon running**. Connect with `SFTP` and `cd /usr/lib/unifi/data/sites/{location}` and `push config.gateway.json`

### 7. Create `config.properties` file  
This file is extends on `config.gateway.json` and need to place in on the same location as `config.gateway.json`.
Follow the next steps for finalized the configuration. 

1. Pull the `config.properties` from the repo.
2. In case the Controller has an **SSH deamon running**. Connect with `SFTP` and `cd /usr/lib/unifi/data/sites/{location}` and `push config.properties`

### 8. Provision the configuration
1. In the **Unifi Controller** -> Devices -> USG.
2. Go to: *Device Management* and click `Force provision`.

The USG status changes to `provisioning` and after a few minutes the status should return back to `connected`.
In case the USG remains in the status `provisioning` please consult the section "Troubleshooting" below.

3. `Force provision` for other devices: *Device Management* and click *Force provision* for all devices.

### 9. Celebrate!.
Wait for it.... you're done. The Internet and IPTV should be working. Test you're IPTV by rebooting the decoders and see if they come back online. If not... read below.

In case the USG or IPTV doesn't work, please consult the section "Troubleshooting" below.

## Troubleshooting
This section describes some of the most commmon issues and (possible) solutions. If these tips don't help you, read the articles mentioned below. Further sources of wisdom include the UBNT, Tweakers.net and KPN fora.

### Troubleshooting provisioning
In case your USG status remains `provisioning` for more then ten minutes consider there is an error in the configuration file.

To troubleshoot look at these logfiles:
* Log into the webinterface of the **Unifi Controller** and check the events and logs.

* `SSH` to the **USG** directly (login using the controller admin username and password) and read the log files.

* `SSH` to the **Unifi Controller** directly and read log files indicating any errors in the provisioning.

### Troubleshooting IPTV

In case IPTV is not working there is a plethora of possible root causes. Below are some of the ones I ran into and the solutions I've found.

IPTV issues:
* IPTV black screen
* Decoder can't connect
* IPTV black screen (after few minutes)

Determining cause and solutions:
1. *Check the IPTV routing*

    1.1 `SSH` into the **USG** and issue the command: `show dhcp client leases`

    1.2 Compare the resulting router and subnet with the settings in the `config.gateway.json` and `update_iptv_route.sh` settings.

    1.3 Adjust the settings in the files to match these returned by the IPTV network of KPN (see the appropriate steps above).

2. *Check the IGMP Proxy*

    2.1 SSH into the **USG** and issue the command: `show protocols igmp-proxy interface` and check that the returned values match the settings expressed in the `config.gateway.json` (on the **Unifi Controller** filesystem).

    2.3 Issue the command: `show ip multicast interfaces` and check the output.

    2.4 Issue the command: `show ip multicast mfc` and check the output.

    2.5 Issue the command: `ps aux | grep igmp` to see if the IGMP proxy is running. If not run: `/opt/vyatta/sbin/config-igmpproxy.pl --action=restart` to start the proxy.

3. *Reprovision the configuration*

    Force a reprovisioning of the configuration from the Unifi controller.

4. *Restart the USG*

    Poor solution, but sometimes helps. After restart retry steps 1 to 3 otherwise, step 5.

5. *Find help.*

    Use your favorite search engine and the links below to read up about possible symptoms, causes and solutions.

### Networking issues
Possible networking issues:
* Slow network (latency)
* Network saturation (throughput)

Determining cause and solutions:
1. Check utilization of the network, switch, AP's and USG in the **Unifi Controller**. Try to determine where issues are located (is it your uplink, is it the local network, etc.).

2. Check if *IGMP Snooping* is supported by your switch (and all other switches in between the NTU and the IPTV decoders)

    Make sure you're switch is IGMP snooping compatible. I chose to use switches from Ubiquity to allow me to manage the entire network using the Unifi Controller.

## Background reading / alternative sources
* Practical guide
    Also defining entire firewall ruleset - without access groups - my main source for this adjusted configuration)<br/> https://www.byluke.nl/tutorial/ubiquiti-usg-werkend-krijgen-kpn-glasvezel/
* Auto-update next hop on IPTV routing:<br/> http://www.pimwiddershoven.nl/entry/kpn-routed-iptv-on-an-ubiquiti-edgerouter-lite-lessons-learned-part-2
* Lessons learned containing Troubleshooting tips for things I didn't run into, but any reader might.<br/> http://www.pimwiddershoven.nl/entry/kpn-router-iptv-on-an-ubiquiti-edgerouter-lite-lessons-learned
* As per hint by @Slootjes https://free2wifi.nl/2018/09/25/ubnt-usg-iptv/ 

