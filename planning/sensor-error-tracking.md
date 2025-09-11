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
4. **Minimal Overhead**: Lightweight implementation with no performance impact

## Technical Analysis

### Current System Architecture
- **Main Config**: `src/config.yaml` contains JSN-SR04T UART configuration
- **Sensor Stack**: Raw distance → calculated water level → volume conversion
- **Power Management**: Automatic power_supply component (GPIO10) with 1s keep-alive after readings
- **Communication**: UART Mode 2 on GPIO20 (RX) and GPIO21 (TX)
- **Update Cycle**: 20-minute intervals with median filtering

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
   - Power supply component failures to enable
   - Sensor initialization timeouts during 2s enable_time
   - Power supply keep_on_time insufficient for sensor response

## Implementation Plan

### Task 1: Add Simple Error Flag Global
- **File**: `src/config.yaml`
- **Action**: Add a single global variable for error tracking
- **Implementation**:
  ```yaml
  globals:
    - id: sensor_error_flag
      type: bool
      restore_value: false
      initial_value: 'false'  # false = OK, true = Error
  ```

### Task 2: Enhance JSN-SR04T Sensor Configuration
- **File**: `src/config.yaml`
- **Action**: Add error detection using `on_raw_value` event handler
- **⚠️ IMPORTANT**: Preserve ALL existing configuration details when adding the `on_raw_value` handler
- **Implementation**:
  ```yaml
  sensor:
    # JSN-SR04T with automatic power management via power_supply
    # Raw distance sensor (top-mounted, measures distance from sensor to water surface)
    - platform: jsn_sr04t
      id: raw_distance_sensor
      uart_id: uart_bus
      name: "Raw Distance"
      device_class: distance
      icon: "mdi:ruler"
      unit_of_measurement: "m"
      accuracy_decimals: 3
      update_interval: 20min  # Native sensor updates every 20 minutes
      power_supply: jsn_sr04t_power  # Automatic power management
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

### Task 3: Create Home Assistant Binary Sensor
- **File**: `src/config.yaml`
- **Action**: Add binary sensor to expose error status to Home Assistant
- **Implementation**:
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

### Task 4: Build Validation
- **Action**: Validate the implementation through compilation
- **Validation Steps**:
  1. Use `./build.sh --no-flash` to verify YAML syntax and configuration
  2. Check for ESPHome compilation errors
  3. Verify all entity IDs are unique and properly referenced




## Implementation Notes for AI Agent

1. **Git Branch Development**: Create and work on a separate git branch (e.g., `feature/sensor-error-tracking`)
2. **Incremental Commits**: Commit changes after each logical unit of work:
   - Task 1: Add error flag global variable
   - Task 2: Enhance sensor configuration with error detection
   - Task 3: Add Home Assistant binary sensor
   - Task 4: Testing and validation
3. **Configuration Validation**: Use `./build.sh --no-flash` to validate YAML syntax and compile without flashing after each change
4. **Compilation Testing**: Ensure ESPHome can successfully compile the configuration
5. **Entity Validation**: Verify all sensor and binary_sensor entities are properly defined
6. **Project Status Updates**: During implementation, update the project status from 📐 Planning to 🔨 Implementing to 🩺 Testing to ✅ DONE as work progresses
7. **Checklist Management**: Mark implementation checklist items as completed (✅) as each task is finished
8. **Power Supply Compatibility**: Work within existing automatic power management
9. **Documentation Updates**: Update relevant docs after implementation



## Implementation Checklist

### Git Branch Setup
- [ ] Create feature branch `feature/sensor-error-tracking`
- [ ] Switch to feature branch

### Task 1: Add Simple Error Flag Global
- [ ] Add `sensor_error_flag` global variable to `src/config.yaml`
- [ ] Commit: "Add sensor error flag global variable"
- [ ] Build validation: `./build.sh --no-flash`

### Task 2: Enhance JSN-SR04T Sensor Configuration  
- [ ] Locate existing JSN-SR04T sensor configuration in `src/config.yaml`
- [ ] Add `on_raw_value` event handler with NaN detection and error flag logic
- [ ] ⚠️ **CRITICAL**: Preserve ALL existing parameters (id, uart_id, name, device_class, icon, unit_of_measurement, accuracy_decimals, update_interval, power_supply)
- [ ] ⚠️ **CRITICAL**: Keep ALL existing filters unchanged (median, clamp, delta with exact parameters)
- [ ] Commit: "Add error detection to JSN-SR04T sensor"
- [ ] Build validation: `./build.sh --no-flash`

### Task 3: Create Home Assistant Binary Sensor
- [ ] Add binary_sensor template for error status
- [ ] Set appropriate device_class, entity_category, and icon
- [ ] Commit: "Add Home Assistant binary sensor for error status"
- [ ] Build validation: `./build.sh --no-flash`

### Task 4: Build Validation
- [ ] Final build validation with `./build.sh --no-flash`
- [ ] Verify all entity IDs are unique
- [ ] Check for ESPHome compilation warnings

### Project Completion
- [ ] Update project status to ✅ DONE

## Key Architecture Notes

- **Existing Power Management**: The JSN-SR04T already uses `power_supply` component with GPIO10
- **Automatic Cycling**: Sensor is powered on 2s before reading, kept alive 1s after
- **20-minute Intervals**: Native sensor update cycle with median filtering
- **No Manual Power Control**: Recovery must work within the power_supply framework
- **Error Detection Timing**: Must account for power-on delay and sensor response time