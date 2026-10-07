# Remote desktop project: handoff for a local session

Written 2026-10-07 ~20:15 UTC by a cloud Claude session. Goal: replace Parsec with self-built,
self-hosted streaming across home PC, work PC (full admin), and Android phone, all on one tailnet.

## Stack

| Role | Repo (private) | Branch | Upstream |
|---|---|---|---|
| Windows host | SunnyInWukong/Apollo | master | ClassicOldSong/Apollo (Sunshine fork, GPL-3.0) |
| Android client | SunnyInWukong/Artemis-Android | moonlight-noir | ClassicOldSong/moonlight-android |
| Windows client | SunnyInWukong/moonlight-qt | master | moonlight-stream/moonlight-qt |

Each local clone needs `git remote add upstream <upstream url>` to pull upstream changes later
(merge, never rebase). Names were kept as upstream on purpose (no rebrand).

## Status

- Artemis-Android: CI green. Each push to moonlight-noir publishes a release `build-N`;
  https://github.com/SunnyInWukong/Artemis-Android/releases/latest. Build 3 is installed on Brett's phone.
  - Package id `com.limelight.noir.self` (installs beside official Artemis).
  - Signed with `signing/sideload.jks` (committed; password default in `app/build.gradle`). Keep this key:
    a different key means uninstall + reinstall on the phone.
  - CI verifies signer CN and package id before publishing.
- moonlight-qt: CI green (run 37672144813), Windows x64 + arm64 as Actions artifacts only; no release step yet.
  Dependabot config removed (it burned Windows minutes).
- Apollo: CI green on b24ead44 (run 37679992153). Release `build-6` has the NSIS installer + portable zip;
  https://github.com/SunnyInWukong/Apollo/releases/latest. Installer never run on a real PC yet.
  - Fixed: `src/video.cpp` AMF h264 `profile` option referenced `cfg.profile`, which Apollo's `config_t`
    lacks (upstream commit c71ea0a8 broke the Windows build). Now constant `"high"`.
  - Fixed: MSYS2 `makensis` has no plugin dir, so NSIS failed on
    `InstallOptions::initDialog`. Workflow now passes `CPACK_NSIS_EXECUTABLE` = runner's
    `C:/Program Files (x86)/NSIS/makensis.exe`.
  - Portable zip already builds (run 37677586463 artifact). Each master push publishes release `build-N`.
- `remote-kit/phone.ps1`: scrcpy over Tailscale to control the phone from a PC. Parse-checked only; never run on Windows.
- `remote-kit/wake.ps1`: Wake-on-LAN. Ran on Linux pwsh, packet format verified. Remote wake needs an always-on
  LAN box (`-Via user@host` over SSH + python3); magic packets do not cross Tailscale.

## Next steps (in order)

1. Apollo CI is green; on later pushes check with `gh run list -R SunnyInWukong/Apollo -L 3` (`gh run view <id> --log-failed` if red).
2. Install Apollo on this PC: `gh release download -R SunnyInWukong/Apollo -p '*installer.exe'` then run it as admin
   (keep SudoVDA + Virtual Gamepad components). Fallback: official installer from ClassicOldSong/Apollo releases.
3. Open https://localhost:47990, create web UI login. Get Tailscale IP: `tailscale ip -4`.
4. Pair the phone: Artemis > + > Tailscale name or 100.x IP > enter PIN in web UI PIN tab. Stream "Desktop".
5. Repeat 2-4 on the other PC. PC to PC: install moonlight-qt build from Actions artifact (or add a release step like Artemis).
6. Test `phone.ps1` (needs phone Wireless debugging or one `-Usb` run).
7. Decide on WoL relay hardware, or set home PC to never sleep.

## Gotchas

- Private repos: release links 404 unless the browser is logged into GitHub as SunnyInWukong.
- Work PC: corporate AV / firewall may block Apollo's ports (TCP 47984, 47989, 47990, 48010; UDP 47998-48000, 48002, 48010).
  Over Tailscale only the tailnet can reach them.
- Windows Actions minutes bill 2x on private repos; Apollo is ~14 min per build. Avoid pointless pushes to master
  (use `[skip ci]` in docs-only commits).
- Upstream Apollo has no CI of its own (removed 2025-07); `.github/workflows/build-windows.yml` here is ours.

## Constraints from Brett

Terse replies, no em dashes. Laziest working fix, shortest diff. Never weaken tests. Never claim it works without
proof. Drafts only for outbound email; money spend and irreversible actions are staged for him.
