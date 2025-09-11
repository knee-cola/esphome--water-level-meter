# ESPHome Flashing Guide

This guide covers flashing the ESP32-C3 Super Mini with ESPHome firmware for the water level sensor project.

## 🚀 Quick Start

### Using the Build Script (Recommended)

Use the provided `build.sh` bash script for automated building and flashing:

```bash
./build.sh
```

### Interactive Wizard

When started, the script shows an interactive wizard:

| Option | Description | Choices |
|--------|-------------|---------|
| **Flash after building** | Automatically flash after successful build | Yes / No |
| **Flashing method** | Choose connection method | S=Serial / O=OTA |

### Command Line Options

For automation or scripting, bypass the wizard with CLI parameters:

```bash
# Flash via serial after building
./build.sh --flash --method=serial

# OTA update (device must be online)
./build.sh --flash --method=ota

# Flash without `--method` param (will default to "serial")
./build.sh --flash
```

**Parameters:**
- `--flash` - Flash after successful build
- `--method=serial/ota` - Connection method (default: serial)

---

## 🔧 Manual Installation Methods

### Method 1: ESPHome CLI (Advanced Users)

1. **Install ESPHome CLI**
   ```bash
   pip3 install esphome
   ```

2. **Create secrets.yaml**
   ```yaml
   wifi_ssid: "YourWiFiName"
   wifi_password: "YourWiFiPassword"
   ```

3. **Compile and flash**
   ```bash
   esphome run esphome-water-level-meter.yaml
   ```

### Method 2: ESPHome Dashboard

1. **Start ESPHome Dashboard**
   ```bash
   esphome dashboard config/
   ```

2. **Open browser** → http://localhost:6052
3. **Upload** `esphome-water-level-meter.yaml`
4. **Configure WiFi** credentials
5. **Install** → Choose connection method

---

## 📋 Prerequisites

### Hardware Requirements
- ESP32-C3 Super Mini development board
- USB-C cable for serial connection
- Computer with USB port

### Software Requirements
- **Docker** (for build.sh script)
- **Python 3.7+** (for manual ESPHome CLI)
- **Git** (to clone this repository)

---

## 🔌 First-Time Flashing (Serial Connection)

### Step 1: Connect Hardware
1. Connect ESP32-C3 to computer via USB-C cable
2. Put device in flash mode (usually automatic)

### Step 2: Identify Serial Port

**Linux/macOS:**
```bash
# Check for new device
dmesg | tail
ls /dev/ttyUSB* /dev/ttyACM*

# Add user to dialout group (Linux)
sudo usermod -aG dialout $USER
# Re-login after running this command
```

**Windows:**
- Check Device Manager → Ports (COM & LPT)
- Note the COM port number (e.g., COM3)

### Step 3: Flash Firmware
- Run `./build.sh` and select Serial method
- Choose the correct port when prompted
- Wait for compilation and flashing to complete

---

## 📡 Over-The-Air (OTA) Updates

Once initially flashed, subsequent updates can be done wirelessly:

### Prerequisites for OTA
- Device must be online and reachable
- Same WiFi network as your computer
- Device name must be discoverable

### OTA Flashing Steps
```bash
# Using build script
./build.sh --flash --method=ota

# Or manually with ESPHome CLI
esphome run esphome-water-level-meter.yaml
# Select "Wirelessly" when prompted
```

---

## 🐛 Troubleshooting

### Common Issues

| Problem | Solution |
|---------|----------|
| **Port not found** | Check USB cable, try different port, install drivers |
| **Permission denied** | Add user to `dialout` group, use `sudo` |
| **Compilation fails** | Check YAML syntax, update ESPHome version |
| **OTA not working** | Verify device is online, check WiFi credentials |
| **Device not booting** | Hold BOOT button during power-on, try different cable |

### Serial Connection Issues

```bash
# Test serial connection (Linux/macOS)
screen /dev/ttyUSB0 115200

# Windows - use PuTTY or similar terminal
```

### Reset to Factory Firmware
If ESPHome firmware causes issues:

1. **Flash blank firmware**
   ```bash
   esptool.py --chip esp32c3 erase_flash
   ```

2. **Or use ESP32 Flash Download Tool** (Windows)

---

## 💡 Implementation Details

### Build Script Features
- **Docker-based**: Uses ESPHome Docker image (no local dependencies)
- **Cross-platform**: Works on Linux, macOS, and Windows (with WSL)
- **Automated**: Handles compilation and flashing in one command
- **Configurable**: Interactive wizard or CLI parameters

### File Structure
```
ESP32-water-level-meter/
├── esphome-water-level-meter.yaml  # Main configuration
├── secrets.yaml                    # WiFi credentials (create this)
├── build.sh                        # Build and flash script
└── ESPHOME_FLASHING.md             # This guide
```

### Next Steps
After successful flashing:
1. Device will create WiFi hotspot "WaterMeterSetupAP" if WiFi fails
2. Connect to configure WiFi credentials
3. Add device to Home Assistant
4. See [HA_INTEGRATION.md](HA_INTEGRATION.md) for setup instructions

