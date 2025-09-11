# JSN-SR04T Sensor Error Tracking Implementation Plan

## Project Status: 📐 Planning

**Progress Indicators:**
- 📐 Planning → 🔨 Implementing → 🩺 Testing → ✅ DONE

## Project Overview

Develop a comprehensive error tracking system for the JSN-SR04T ultrasonic sensor in the ESPHome water level monitoring system. This will provide Home Assistant with visibility into sensor health, reading failures, and diagnostic information to improve system reliability and maintenance scheduling.

## Objectives

1. **Basic Error Detection**: Simple binary flag to indicate sensor reading failure (false=OK, true=Error)
2. **Home Assistant Integration**: Expose error status through HA-compatible binary sensor
3. **Automatic Recovery**: Reset error flag to false after successful reading

**Implementation Principle**: Minimal viable solution - implement only the essential functionality requested without extra logging, error checking, or monitoring features.

## Technical Analysis

### Current System Architecture
- **Main Config**: `src/config.yaml` contains JSN-SR04T UART configuration
- **Sensor Stack**: Raw distance → calculated water level → volume conversion
- **Power Management**: Interval-based GPIO switch control (GPIO10) - JSN-SR04T platform does not support power_supply component
- **Communication**: UART Mode 2 on GPIO20 (RX) and GPIO21 (TX)
- **Update Cycle**: 20-minute interval timer with manual power control and median filtering

### Error Sources to Track
1. **UART Communication Errors**
   - Timeout waiting for sensor response
   - Invalid data format received
   - Checksum validation failures
   - No response from sensor

2. **Data Validation Errors**
   - Readings outside valid range (20cm-5m)
   - NaN values from calculations
   - Consecutive identical readings (stuck sensor)
   - Extreme value variations (noise/interference)

3. **Power Management Issues**
   - GPIO switch failures to enable sensor power
   - Sensor initialization timeouts during 2s stabilization period
   - Interval timing issues affecting sensor power cycles



## Implementation Checklist

### Git Branch Setup
- [ ] Create feature branch `feature/sensor-error-tracking`
- [ ] Switch to feature branch

### Add Error Flag Global Variable
- [ ] Add `sensor_error_flag` global variable to `src/config.yaml`
- [ ] Commit: "Add sensor error flag global variable"
- [ ] Build validation: `./build.sh`

### Enhance JSN-SR04T Sensor Configuration  
- [ ] Locate existing JSN-SR04T sensor configuration in `src/config.yaml`
- [ ] Add `on_raw_value` event handler with NaN detection and error flag logic
- [ ] ⚠️ **CRITICAL**: Preserve ALL existing parameters (id, uart_id, name, device_class, icon, unit_of_measurement, accuracy_decimals, update_interval: never)
- [ ] ⚠️ **CRITICAL**: Keep ALL existing filters unchanged (median, clamp, delta with exact parameters)
- [ ] Commit: "Add error detection to JSN-SR04T sensor"
- [ ] Build validation: `./build.sh`

### Create Home Assistant Binary Sensor
- [ ] Add binary_sensor template for error status
- [ ] Set appropriate device_class, entity_category, and icon
- [ ] Commit: "Add Home Assistant binary sensor for error status"
- [ ] Build validation: `./build.sh`

### Final Validation
- [ ] Final build validation with `./build.sh`
- [ ] Verify all entity IDs are unique
- [ ] Check for ESPHome compilation warnings
- [ ] Update project status to ✅ DONE

## Key Architecture Notes

- **Current Power Management**: Uses interval-based GPIO switch control (GPIO10) - JSN-SR04T platform does not support power_supply component
- **Interval-Based Cycling**: 20-minute interval timer controls power: ON → 2s stabilization → sensor reading → 1s delay → OFF
- **Update Control**: Sensor uses `update_interval: never` and is triggered by `component.update` in interval automation
- **Error Detection Timing**: Error detection occurs during the interval-controlled sensor reading cycle
- **Power Control Integration**: Error tracking must work within the existing interval + switch power management framework
- **Error Detection Timing**: Must account for power-on delay and sensor response time