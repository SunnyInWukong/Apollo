# remote-kit

Setup for Brett's machines: home PC, work PC, phone, all on one tailnet.

| Direction | Host side | Client side |
|---|---|---|
| PC → PC | Apollo (this repo, `Build Windows` artifact) | Moonlight (SunnyInWukong/moonlight-qt artifact) |
| Phone → PC | Apollo | Artemis (SunnyInWukong/Artemis-Android artifact) |
| PC → Phone | phone's adbd | `phone.ps1` (scrcpy) |

Pairing over Tailscale: Moonlight/Artemis → Add PC → enter the host's Tailscale name or 100.x IP.
Enter the PIN in Apollo's web UI at https://localhost:47990 on the host. No port forwarding.

`wake.ps1` sends Wake-on-LAN. Magic packets don't cross Tailscale; see the script header for the relay setup.
