# JSN-SR04T Sensor Error Tracking Implementation Plan

## Project Status: ✅ DONE

**Progress Indicators:**
- 📐 Planning → 🔨 Implementing → 🩺 Testing → ✅ DONE

## Project Overview

Develop a comprehensive error tracking system for the JSN-SR04T ultrasonic sensor in the ESPHome water level monitoring system. This will provide Home Assistant with visibility into sensor health, reading failures, and diagnostic information to improve system reliability and maintenance scheduling.

## Objectives

1. **Basic Error Detection**: Simple binary flag to indicate sensor reading failure (false=OK, true=Error)
2. **Home Assistant Integration**: Expose error status through HA-compatible binary sensor
3. **Automatic Recovery**: Reset error flag to false after successful reading

**Implementation Principle**: Minimal viable solution - implement only the essential functionality requested without extra logging, error checking, or monitoring features.

## Technical Context

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

## Implementation Details

### 1. Error Flag Global Variable
Add a single global variable for error tracking:
```yaml
globals:
  - id: sensor_error_flag
    type: bool
    restore_value: false
    initial_value: 'false'  # false = OK, true = Error
```

### 2. Enhanced JSN-SR04T Sensor Configuration
Add error detection using `on_raw_value` event handler:
```yaml
sensor:
  # JSN-SR04T ultrasonic distance sensor with interval-based power management
  # Note: jsn_sr04t platform does not support power_supply component
  # Raw distance sensor (top-mounted, measures distance from sensor to water surface)
  - platform: jsn_sr04t
    id: raw_distance_sensor
    uart_id: uart_bus
    name: "Raw Distance"
    device_class: distance
    icon: "mdi:ruler"
    unit_of_measurement: "m"
    accuracy_decimals: 3
    update_interval: never  # Controlled by interval component
    # ADD THIS NEW EVENT HANDLER:
    on_raw_value:
      - lambda: |-
          // Check for valid reading from sensor
          if (isnan(x)) {
            ESP_LOGW("sensor", "JSN-SR04T reading failed");
            id(sensor_error_flag) = true;
          } else {
            // Successful reading - clear error flag
            if (id(sensor_error_flag)) {
              ESP_LOGI("sensor", "JSN-SR04T reading recovered");
            }
            id(sensor_error_flag) = false;
          }
    # PRESERVE ALL EXISTING FILTERS EXACTLY AS THEY ARE:
    filters:
      - median:
          window_size: 3        # or 5 if you burst 5 reads
          send_every: 3         # (or 5) publish only the aggregated value
          send_first_at: 3
      - clamp:
          min_value: 0.0
          max_value: 3.0        # adjust to your max measurable distance (m)
      - delta: 0.01             # optional: only publish if change >= 1 cm (if units are meters)
```

### 3. Home Assistant Binary Sensor
Add binary sensor to expose error status to Home Assistant:
```yaml
binary_sensor:
  - platform: template
    name: "Sensor Error"
    id: sensor_error_binary
    lambda: 'return id(sensor_error_flag);'
    device_class: problem
    entity_category: diagnostic
    icon: "mdi:alert-circle"
```

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