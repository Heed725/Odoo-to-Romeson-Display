# Odoo POS to Romeson LED8 Customer Display

Connect a standard Odoo Point of Sale session running in Microsoft Edge, Google Chrome, or Mozilla Firefox to a Romeson eight-digit rear customer display on Windows.

The connector reads the visible numeric order total from Odoo POS, sends it to a local Windows bridge, and writes the LED8/ESC-POS byte sequence to `COM2` at `2400` baud.

## Browser and Odoo compatibility

Version 2.0 removes the fixed website list. It activates on the standard Odoo POS route on **any HTTP or HTTPS host**:

- `http://<any-host>/pos/ui...`
- `https://<any-host>/pos/ui...`

This includes Odoo Online, Odoo.sh, locally hosted Odoo, IP-address installations, and custom domains. The supplied builds support:

| Browser | Extension folder |
|---|---|
| Microsoft Edge | `extension/` |
| Google Chrome | `extension/` |
| Mozilla Firefox | `extension-firefox/` |

The total reader supports standard Odoo POS layouts and common layouts used by Odoo 14 through current releases. A heavily customized POS theme can still require an additional CSS selector.

## Confirmed hardware configuration

| Setting | Value |
|---|---|
| Display | Romeson eight-digit LED8 customer display |
| Port | COM2 |
| Baud rate | 2400 |
| Serial format | 8 data bits, no parity, 1 stop bit |
| Protocol | LED8 / ESC-POS-compatible commands |
| Local bridge | `http://127.0.0.1:8765` |

## How it works

```text
Odoo POS in Edge, Chrome, or Firefox
       |
       v
Browser extension reads the visible numeric total
       |
       v
Local Windows bridge on 127.0.0.1:8765
       |
       v
COM2 at 2400 baud
       |
       v
Romeson LED8 customer display
```

Only the numeric total is sent to the local bridge. Product names, customer details, passwords, and payment information are not transmitted.

## Installation

1. Download or clone this repository.
2. Right-click `install.bat` and select **Run as administrator**.
3. Load the correct extension folder for your browser.
4. Restart the Odoo POS page.
5. Pin the extension and choose **Test 25,000.00**.

### Microsoft Edge

1. Open `edge://extensions`.
2. Enable **Developer mode**.
3. Click **Load unpacked**.
4. Select `%LOCALAPPDATA%\RomesonOdooBridge\extension`.

### Google Chrome

1. Open `chrome://extensions`.
2. Enable **Developer mode**.
3. Click **Load unpacked**.
4. Select `%LOCALAPPDATA%\RomesonOdooBridge\extension`.

### Mozilla Firefox

1. Open `about:debugging#/runtime/this-firefox`.
2. Click **Load Temporary Add-on**.
3. Select `%LOCALAPPDATA%\RomesonOdooBridge\extension-firefox\manifest.json`.

A temporary Firefox add-on must be loaded again after Firefox restarts. Permanent normal-Firefox installation requires a Mozilla-signed package or enterprise deployment policy.

The bridge starts automatically when the Windows user signs in.

## Test the display from CLI

Configure COM2:

```cmd
mode COM2 BAUD=2400 PARITY=N DATA=8 STOP=1
```

Send `25000.00`:

```cmd
powershell -Command "$p=New-Object System.IO.Ports.SerialPort 'COM2',2400,'None',8,'One'; $p.Open(); $b=[byte[]](@(27,64,12,27,115,50)+[Text.Encoding]::ASCII.GetBytes('25000.00')); $p.Write($b,0,$b.Length); Start-Sleep -Seconds 3; $p.Close()"
```

## Repository structure

```text
bridge/                          Windows serial bridge
extension/                       Edge and Chrome extension
extension-firefox/               Firefox extension
docs/                            Installation documentation
releases/                        Ready-to-install release packages
install.bat                      Installer and automatic startup setup
start-bridge.bat                 Manual bridge start
stop-bridge.bat                  Manual bridge stop
test-display.bat                 Hardware/bridge test
uninstall.bat                    Connector removal helper
```

## Troubleshooting

- **Extension says Not connected:** run `start-bridge.bat`.
- **Nothing happens on a self-hosted instance:** confirm its POS URL contains `/pos/ui`, then reload the extension and the POS page.
- **Access to COM2 is denied:** close other applications using COM2, then restart the bridge.
- **Corrupted symbols:** restart the display and confirm it is using 2400 baud.
- **Test works but Odoo does not:** the POS may use a customized total element; add its selector to `content.js`.
- **Diagnostic status:** open `http://127.0.0.1:8765/health`.
- **Log file:** `%LOCALAPPDATA%\RomesonOdooBridge\bridge.log`.

## Version

Development version: **2.0.0**
