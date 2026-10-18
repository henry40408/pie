# pie

Debian 13 Lima VM for [pi](https://pi.dev), isolated from the host.

- No host mounts, no forwarded ssh-agent, no port forwarding, no proxy env. Get code in with `git clone` inside the VM.
- **Not a network sandbox.** The guest can reach services the host binds to localhost only, through `host.lima.internal` (192.168.5.2). Lima's user-mode network does this by design. Do not run unauthenticated local services on the host while the VM runs untrusted code.
- Two named volumes (Lima additional disks) survive `make recreate` and `make destroy`:
  - `pi-config` → `/mnt/lima-pi-config` (`PI_CODING_AGENT_DIR`: settings, auth, sessions)
  - `workspace` → `/mnt/lima-workspace`
- Disk names must be 11 characters or fewer. Lima labels disks `lima-<name>` and an ext4 label holds 16 characters. A longer name is never found by label, so Lima reformats the disk on every boot.
- Runtimes are managed by [mise](https://mise.jdx.dev). `vm/mise.toml` pins node, pi, fd and ripgrep (pi would otherwise download the last two itself) (kept out of the repo root so host mise never loads it). `versions.env` pins mise itself (with checksum).

## Usage

```
make up                  # create/start the VM, install mise, node, pi (idempotent)
make shell               # shell in /mnt/lima-workspace (under Ghostty, installs its terminfo in the VM once)
make pi                  # run pi in /mnt/lima-workspace (ARGS="-c" passes arguments; the host shell parses ARGS, so quote carefully)
make update V=1.2.0      # pin another pi version (refused if published < 7 days ago); review and commit vm/mise.toml
make recreate            # rebuild the VM, keep volumes
make status | down | destroy
make purge-data          # delete the volumes (asks first)
```

Requires Apple Silicon (`vmType: vz`, `arch: aarch64`) and Lima 2.x.
Extra runtimes: add them to `vm/mise.toml`, then `make up`.
