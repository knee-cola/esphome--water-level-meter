# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an ESPHome-based water level monitoring system using ESP32-C3 Super Mini and JSN-SR04T ultrasonic sensor. It creates a Home Assistant-ready sensor that measures water tank levels with configurable parameters and provides wireless monitoring capabilities.

## Core Architecture

### ESPHome Configuration Structure
The main configuration is in `src/config.yaml` with a hierarchical structure:
- **Device & Connectivity**: ESP32-C3 settings, WiFi, API, OTA updates
- **Hardware Communication**: UART interface for JSN-SR04T sensor
- **Sensor Stack**: Raw distance → calculated water level percentage → volume in liters
- **User Configuration**: Template number entities for tank calibration
- **Alerting**: Binary sensors for low water warnings and device status

### Data Flow
```
JSN-SR04T (UART Mode 2) → ESP32-C3 → Template Calculations → Home Assistant
                                   ↓
                              Web Interface (Port 80)
```

## Essential Commands

### Build and Deploy
```bash
# Interactive build wizard (recommended for new users)
./build.sh

# Build and flash via serial (initial deployment)
./build.sh --flash --method=serial

# Build and OTA update (subsequent deployments)  
./build.sh --flash --method=ota

# Monitor device logs
./monitor.sh
```

### Docker-Based Development
Uses `esphome/esphome:2025.8.1` image with volume mounting for cross-platform compatibility.

### Configuration Requirements
The project includes a template `src/secrets.yaml` file with placeholder values. **You must update this file with your actual credentials before building:**

```yaml
wifi_ssid: "Your-WiFi-Network-Name"          # Replace with your WiFi name
wifi_password: "your-wifi-password"           # Replace with your WiFi password  
api_key: "0123...abcdef"                      # Generate with: openssl rand -hex 32
ota_password: "your-secure-ota-password"      # Choose a secure OTA password
```

> **🔒 Security Note:** After updating `secrets.yaml` with real values, uncomment the `secrets.yaml` line in `.gitignore` to prevent accidentally committing private credentials to version control.

## Hardware Integration Notes

### Critical Hardware Requirements
- **JSN-SR04T Modification**: Must solder 120kΩ resistor to R27 pad for UART Mode 2
- **Logic Level Conversion**: Required for 5V sensor ↔ 3.3V ESP32-C3 communication
- **Pin Assignments**: 
  - UART on GPIO20 (RX) and GPIO21 (TX)
  - **SSR Control on GPIO10** for JSN-SR04T power management
- **Solid State Relay**: 3.3V trigger compatible, rated for 5V/50mA JSN-SR04T power
- **Power Control**: SSR switches JSN-SR04T VCC to prevent stuck sensor states

### Network Configuration
- Fixed IP (192.168.0.156) configured for Docker swarm OTA compatibility
- Fallback AP mode: SSID "WaterMeterSetupAP", password "12345678"

## Code Conventions

### YAML Configuration Style
- 2-space indentation (strict)
- `snake_case` for internal IDs (`raw_distance_sensor`)
- `Title Case` for display names ("Water Tank Level")
- `kebab-case` for device names (`water-level-meter`)
- Secrets via `!secret` references
- Entity categories: `config` for setup-only parameters

### Template Sensor Patterns
```yaml
lambda: |-
  // Always check for NaN values
  if (isnan(raw_value)) return NAN;
  
  // Implement proper range validation
  if (value < min_value) value = min_value;
  if (value > max_value) value = max_value;
  
  return calculated_value;
```

## Task Completion Guidelines

### For Configuration Changes
1. Edit `src/config.yaml`
2. Compile with `./build.sh` to validate
3. Flash to device using appropriate method (serial/OTA)
4. Monitor with `./monitor.sh` to verify functionality
5. Test via web interface or Home Assistant integration

### For Script Modifications  
1. Test both interactive and CLI modes of build/monitor scripts
2. Verify Docker container cleanup and device access
3. Test cross-platform compatibility (Linux primary target)

### Hardware Validation
- Verify pin assignments match physical connections
- Confirm voltage level compatibility (3.3V/5V logic)
- Test UART communication after sensor interface changes
- Validate sensor readings are within expected ranges (20cm-5m)

## Documentation Structure

Comprehensive documentation in `docs/`:
- `ESPHOME_FLASHING.md`: Step-by-step flashing guide
- `JSN‑SR04T.md`: Sensor technical details and modification
- `WIRING_SCHEMATICS.md`: Complete wiring diagrams
- `HA_INTEGRATION.md`: Home Assistant setup
- `TROUBLESHOOTING.md`: Common issues and solutions

## Development Notes

- No traditional linters; ESPHome provides YAML validation and configuration warnings
- Build artifacts (`.esphome/`) and secrets are gitignored
- Uses ESP-IDF framework for ESP32-C3 (more robust than Arduino framework)
- Web server on port 80 for local diagnostics and configuration
- Template sensors calculate water level percentage and volume from raw distance measurements
- Native 20-minute update intervals with automatic power management via power_supply component