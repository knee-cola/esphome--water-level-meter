# SSR Power Control Implementation Plan for JSN-SR04T

## Overview
Implement solid state relay (SSR) control to manage JSN-SR04T sensor power supply via ESP32-C3 GPIO pin. The sensor will be powered off between readings to reduce power consumption and extend hardware lifespan.

## Current System Analysis

### Pin Usage (src/config.yaml)
- **GPIO20**: UART RX (JSN-SR04T communication)
- **GPIO21**: UART TX (JSN-SR04T communication)

### Available GPIO Pins for SSR Control
Based on ESP32-C3 Super Mini research:
- **Available digital GPIO pins**: GPIO0, GPIO1, GPIO2, GPIO3, GPIO4, GPIO5, GPIO6, GPIO7, GPIO8, GPIO9, GPIO10
- **Reserved/Special pins to avoid**:
  - GPIO8: Connected to onboard blue LED
  - GPIO9: Connected to BOOT button
  - GPIO4-GPIO7: Reserved for JTAG debugging
  - GPIO20/GPIO21: Already used for UART

### Recommended SSR Control Pin
**GPIO10** - Best choice because:
- Not connected to any special functions
- Not used by current configuration
- Supports digital output
- No ADC or special protocol conflicts

## Implementation Strategy

### 1. Hardware Requirements
- **Solid State Relay**: 3.3V trigger compatible (or with level shifter)
- **SSR Specifications**: 
  - Input: 3-32VDC control voltage
  - Output: Rated for JSN-SR04T power requirements (typically 5V, <50mA)
  - Low-trigger type preferred for better power efficiency

### 2. ESPHome Configuration Changes

#### A. Add Switch Component for SSR Control
```yaml
switch:
  - platform: gpio
    pin: GPIO10
    id: sensor_power_control
    name: "JSN-SR04T Power Control"
    inverted: true  # For low-trigger SSRs
    restore_mode: RESTORE_DEFAULT_OFF
    internal: true  # Hide from Home Assistant UI
```

#### B. Sensor Configuration (No Changes Needed)
```yaml
sensor:
  - platform: jsn_sr04t
    id: raw_distance_sensor
    uart_id: uart_bus
    name: "Raw Distance"
    # ... existing config unchanged ...
    update_interval: never  # Already set
    # No on_value callback - power control handled in interval
```

#### C. Update Interval Configuration
```yaml
interval:
  - interval: 1h
    then:
      # Power on sensor
      - switch.turn_on: sensor_power_control
      - delay: 2s  # Allow sensor to stabilize
      # Take readings with guaranteed power-off
      - component.update: raw_distance_sensor
      - delay: 2s
      - component.update: raw_distance_sensor
      - delay: 2s
      - component.update: raw_distance_sensor
      - delay: 1s  # Allow final reading to complete
      # Always power off sensor
      - switch.turn_off: sensor_power_control
```

### 3. Power-On Sequence Timing
1. **SSR Turn-On**: GPIO10 goes LOW (for low-trigger SSR)
2. **Stabilization**: 2-second delay for JSN-SR04T to initialize
3. **Reading Sequence**: 3 sensor measurements with 2s intervals
4. **Final Delay**: 1-second delay to ensure last reading completes
5. **Guaranteed Power-Off**: SSR turned off regardless of sensor response

### 4. Benefits
- **Power Savings**: ~95% reduction in sensor power consumption
- **Hardware Longevity**: Reduced thermal stress on JSN-SR04T
- **EMI Reduction**: Sensor only active during measurements
- **Flexibility**: SSR can be controlled manually via Home Assistant if needed

## Documentation Updates Required

### 1. WIRING_SCHEMATICS.md
- Add SSR wiring diagram
- Update pin assignment table
- Include power supply routing through SSR
- Add safety notes for high-voltage SSR handling

### 2. JSN‑SR04T.md
- Document power control modification
- Add section on SSR integration
- Update sensor initialization timing requirements
- Include troubleshooting for power control issues

### 3. TROUBLESHOOTING.md
- Add SSR-related troubleshooting section
- Power-on sequence debugging steps
- SSR failure detection methods
- Sensor not responding after power cycle

### 4. HA_INTEGRATION.md
- Document new power control switch entity
- Explain manual override capabilities
- Update sensor entity behavior descriptions

### 5. CLAUDE.md
- Update pin assignment documentation
- Add SSR hardware requirements
- Include power control in build/test procedures

## Implementation Phases

### Phase 1: Configuration Updates
1. Update `src/config.yaml` with SSR switch and modified intervals
2. Test compilation with `./build.sh`
3. Validate YAML syntax and ESPHome compatibility

### Phase 2: Hardware Integration
1. Install SSR in power supply line
2. Connect GPIO10 to SSR control input
3. Verify proper voltage levels and isolation

### Phase 3: Testing & Validation
1. Flash updated configuration via OTA
2. Monitor power control sequence with `./monitor.sh`
3. Verify sensor readings maintain accuracy
4. Test power consumption reduction

### Phase 4: Documentation
1. Update all identified documentation files
2. Create wiring diagrams for SSR integration
3. Add troubleshooting procedures
4. Update project overview and build instructions

## Risk Mitigation

### Potential Issues
- **Sensor initialization delay**: JSN-SR04T may need longer stabilization time
- **UART communication**: Power cycling might affect UART state
- **SSR leakage**: Some SSRs have small leakage current when "off"
- **Timing sensitivity**: Sensor readings might be affected by power control timing
- **Reading failures**: Sensor may not respond, but power-off must still occur

### Mitigation Strategies
- Configurable delays via template numbers
- UART re-initialization if needed
- High-quality SSR selection with minimal leakage
- Extensive testing with various timing configurations
- **Guaranteed power-off**: Use interval-based control, not sensor callbacks
- **Timeout protection**: Fixed timing ensures power control regardless of sensor state

## Success Criteria
- [ ] Sensor maintains reading accuracy (±1cm)
- [ ] Power consumption reduced by >90% during idle periods
- [ ] No communication errors during power cycles
- [ ] Reliable operation over 24+ hour test period
- [ ] All documentation updated and accurate
- [ ] Home Assistant integration maintains functionality