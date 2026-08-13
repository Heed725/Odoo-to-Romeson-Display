# Odoo POS to Romeson LED8 Customer Display

Connect an Odoo Point of Sale session running in Microsoft Edge to a Romeson eight-digit rear customer display on Windows.

The connector reads the visible numeric order total from Odoo POS, sends it to a local Windows bridge, and writes the LED8/ESC-POS byte sequence to `COM2` at `2400` baud.

## Supported Odoo POS sites

- `https://stage.bahdela.or.tz/pos/ui/*`
- `https://erp.bahdela.co.tz/pos/ui/*`
- `https://*.odoo.com/pos/ui/*`

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
Odoo POS in Edge
       |
       v
Edge extension reads the visible numeric total
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

## Quick installation

1. Download `releases/Romeson-Odoo-LED8-v1.0.1.zip`.
2. Extract the ZIP to a normal Windows folder.
3. Right-click `install.bat` and select **Run as administrator**.
4. Open `edge://extensions` in Microsoft Edge.
5. Enable **Developer mode**.
6. Click **Load unpacked**.
7. Select `%LOCALAPPDATA%\RomesonOdooBridge\extension`.
8. Pin **Odoo POS to Romeson LED8**.
9. Click the extension and choose **Test 25,000.00**.
10. Open an Odoo POS session and add a product.

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
extension/                       Microsoft Edge extension
docs/                            Word installation guide
releases/                        Ready-to-install ZIP package
install.bat                      Installer and automatic startup setup
start-bridge.bat                 Manual bridge start
stop-bridge.bat                  Manual bridge stop
test-display.bat                 Hardware/bridge test
uninstall.bat                    Connector removal helper
```

## Troubleshooting

- **Extension says Not connected:** run `start-bridge.bat`.
- **Access to COM2 is denied:** close other applications using COM2, then restart the bridge.
- **Corrupted symbols:** restart the display and confirm it is using 2400 baud.
- **CLI works but Odoo does not:** confirm the Edge extension is loaded and the URL contains `/pos/ui/`.
- **Diagnostic status:** open `http://127.0.0.1:8765/health`.
- **Log file:** `%LOCALAPPDATA%\RomesonOdooBridge\bridge.log`.

See [the complete Word installation guide](docs/Romeson_Odoo_POS_LED8_Installation_Guide.docx) for detailed setup, validation, updating, and uninstallation instructions.

## Version

Current release: **1.0.1**
