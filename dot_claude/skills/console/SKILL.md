---
name: console
description: |
  Access the terminal/console of a local or remote machine. Picks the right
  method from five options: mcp-ssh-wingman (SSH), mcp-jetkvm (KVM over IP for
  lab-ctrl-1), mcp-redfish (Serial-Over-LAN via BMC), ser2net (UART over network),
  or screen on a local USB serial device. Use when you need a shell, serial
  console, SOL session, or out-of-band access to any node.
user-invocable: true
---

# /console — Access a Machine's Terminal or Console

Choose the right access method, connect, and interact with the target machine.

## Method Selection

Work through these questions in order — stop at the first match.

```
1. Is a USB-serial cable physically plugged into this machine right now?
   → screen /dev/tty.usbserial-*

2. Does the machine have a BMC (iDRAC, iLO, IPMI, Redfish)?
   → mcp-redfish  (Serial-Over-LAN)

3. Is the target lab-ctrl-1 / 192.168.6.200, or do you need
   KVM / BIOS / pre-boot access to that machine?
   → mcp-jetkvm

4. Is it a homelab node with a UART port wired to a ser2net server?
   → ser2net

5. Is the machine reachable via SSH?
   → mcp-ssh-wingman
```

If none match, ask the user for more context before proceeding.

---

## Methods

### mcp-ssh-wingman — SSH

**Use for:** any machine reachable over the network where you just need a shell.

The `mcp-ssh-wingman` MCP server manages SSH sessions. It uses the session name
`mcp-wingman` (configured in the MCP server arguments).

- Prefer key-based auth; 1Password SSH agent is available on macOS.
- For hosts not in `~/.ssh/config`, confirm the user and key before connecting.
- After connecting, confirm the hostname and OS with `uname -a` or `hostname`.

---

### mcp-jetkvm — KVM over IP

**Use for:** lab-ctrl-1 (`192.168.6.200`), or any machine that needs keyboard/
video/mouse access (BIOS, boot menu, OS installer, hung console).

The `mcp-jetkvm` MCP server connects to the JetKVM device. Credentials are
injected via 1Password at apply time.

Key capabilities:
- Send keystrokes (including Ctrl-Alt-Del, function keys, arrow keys)
- Capture screen state
- Mount virtual media (ISO images)

**When to prefer over SSH:** machine won't boot, OS not yet installed, need BIOS
settings, SSH daemon is down, or network is not yet configured.

---

### mcp-redfish — Serial-Over-LAN (BMC)

**Use for:** servers with a BMC that exposes a Redfish API (Dell iDRAC, HPE iLO,
Supermicro, ASRockRack, etc.) when you need the serial console independently of
the OS network stack.

> **Note:** `mcp-redfish` is not yet wired into the MCP config. Before using,
> verify the server is listed in `dot_claude/mcp-servers-personal.json.tmpl`
> and that credentials are stored in 1Password.

Useful facts:
- SOL session survives OS crashes and reboots — you see the boot sequence.
- BMC access is on the management network, separate from the data plane.
- To find the BMC IP: check the DHCP lease list, `ipmitool lan print`, or the
  physical label on the server.

---

### ser2net — UART Console over Network

**Use for:** homelab nodes with a serial/UART port wired to a ser2net host
(a machine running the `ser2net` daemon that bridges serial ports to TCP).

Connection pattern:
```
telnet <ser2net-host> <port>
# or
nc <ser2net-host> <port>
```

Before connecting:
1. Confirm which ser2net host serves the target node's UART.
2. Confirm the TCP port assigned to that serial device (`/etc/ser2net.conf` or
   `/etc/ser2net.yaml` on the ser2net host).
3. Confirm the baud rate matches the target (common: 115200 8N1).

Escape sequence to exit a ser2net telnet session: `Ctrl-]` then `quit`.

---

### screen — Local USB Serial

**Use for:** a machine physically connected to this computer via a USB-to-serial
adapter right now.

```bash
# List available serial devices
ls /dev/tty.usbserial-*

# Connect (replace DEVICE and BAUD as needed)
screen /dev/tty.usbserial-XXXXXX 115200

# Common baud rates: 9600, 57600, 115200
```

Escape sequence to detach/exit screen: `Ctrl-A` then `K` (kill), or `Ctrl-A \`.

If multiple `/dev/tty.usbserial-*` devices exist, identify the right one by
unplugging and re-plugging (`ls /dev/tty.usbserial-*` before and after).

---

## General Console Workflow

1. **Identify the target** — hostname, IP, or physical location.
2. **Choose the method** using the decision tree above.
3. **Connect** and confirm you have the right machine (prompt, hostname, MAC).
4. **Do the work** — capture relevant output, run diagnostics, make changes.
5. **Exit cleanly** — use the appropriate escape sequence; don't leave dangling sessions.

## Output

When reporting back from a console session:
- Quote the exact terminal output for errors or unexpected state.
- Note the access method used and the target identifier.
- Flag anything that suggests the machine is in a degraded or unexpected state.
