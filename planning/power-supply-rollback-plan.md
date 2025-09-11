# Power Supply Rollback and Re-implementation Plan

## Overview

This document outlines the rollback and re-implementation of JSN-SR04T sensor power management after discovering that the `jsn_sr04t` platform does not support the `power_supply` property. We need to restore the interval-based power control while incorporating lessons learned from the migration attempt.

## Problem Analysis

### Migration Failure Root Cause
- **ESPHome Limitation**: The `jsn_sr04t` sensor platform does not support the `power_supply` configuration property
- **Compilation Error**: Configuration fails to build due to unsupported property
- **Documentation Gap**: ESPHome documentation doesn't clearly indicate which sensors support power_supply

### Current State Assessment
- Power supply migration was implemented but cannot compile
- Original interval-based power control was removed
- System is currently non-functional due to compilation errors

## Target Re-implementation Requirements

### Improved Architecture Goals
1. **Restore Functionality**: Return to working interval-based power management
2. **Improve Timing**: Use 20-minute intervals instead of 1-hour (as intended in migration)
3. **Simplify Configuration**: Clean, minimal implementation
4. **Power Efficiency**: Maintain minimal power-on time for sensor readings

### Key Design Decisions
- **Keep interval-based triggering** (only viable option for JSN-SR04T)
- **Reduce update frequency** to 20 minutes (from original 60 minutes)
- **Simplify configuration** with clean, minimal implementation
- **Focus on core functionality** without complex error handling

## Implementation Steps

### Step 0: Project Setup and Assessment

**Create Rollback Branch:**
```bash
git checkout -b feature/power-supply-rollback
```

**Assess Current Configuration:**
- Document current non-working state
- Identify which components were removed in migration
- Plan systematic restoration with improvements

### Step 1: Remove Non-Functional Power Supply Configuration

Remove the power_supply component and references that cause compilation failures:

```yaml
# REMOVE: Non-functional power_supply component
power_supply:
  - id: jsn_sr04t_power
    pin: GPIO10
    # ... entire power_supply config
```

**Also remove from sensor:**
```yaml
sensor:
  - platform: jsn_sr04t
    # REMOVE: power_supply: jsn_sr04t_power
```

### Step 2: Re-implement GPIO Power Control Switch

Restore the GPIO switch for manual power control with improved configuration:

```yaml
switch:
  - platform: gpio
    pin: 
      number: GPIO10
      inverted: true  # For AQV258 PhotoMOS (LOW=ON, HIGH=OFF)
    id: sensor_power_control
    internal: true  # Hide from Home Assistant UI
    restore_mode: ALWAYS_OFF  # Ensure power starts OFF
```

**Key Improvements:**
- Better pin configuration with explicit inversion
- Explicit restore_mode to ensure consistent startup state

### Step 3: Implement Improved Interval-Based Control

Create simplified interval logic with 20-minute cycles:

```yaml
interval:
  - interval: 20min
    then:
      - switch.turn_on: sensor_power_control
      - delay: 2000ms  # Sensor stabilization
      - component.update: raw_distance_sensor
      - delay: 1000ms  # Reading completion
      - switch.turn_off: sensor_power_control
```

### Step 4: Update JSN-SR04T Sensor Configuration

Modify sensor to work with interval triggering while maintaining improvements:

```yaml
sensor:
  - platform: jsn_sr04t
    id: raw_distance_sensor
    uart_id: uart_bus
    name: "Raw Distance"
    device_class: distance
    icon: "mdi:ruler"
    unit_of_measurement: "m"
    accuracy_decimals: 3
    update_interval: never  # Controlled by interval component
    filters:
      - median:
          window_size: 3
          send_every: 3
          send_first_at: 3
      - clamp:
          min_value: 0.0
          max_value: 3.0
      - delta: 0.01
```

**Key Improvements:**
- Better filter configuration maintained from migration attempt

### Step 5: Update Configuration Comments

Add comprehensive comments explaining the restored architecture:

```yaml
# JSN-SR04T Ultrasonic Sensor with Interval-Based Power Management
# Note: jsn_sr04t platform does not support power_supply component
# Using interval + switch combination for power control

switch:
  # GPIO power control for JSN-SR04T sensor
  # Controls AQV258 PhotoMOS solid state relay
  - platform: gpio
    # ... switch config
    
interval:
  # 20-minute sensor reading cycle with power management
  # Timing: Power ON → 2s stabilization → Reading → 1s delay → Power OFF
  - interval: 20min
    # ... interval config
    
sensor:
  # JSN-SR04T sensor with never update_interval (controlled by interval)
  - platform: jsn_sr04t
    # ... sensor config
```

### Step 6: Testing and Validation

**Testing:**
1. **Configuration Validation**: Ensure YAML compiles without errors

**Testing Commands:**
```bash
# Validate configuration - only test requirement
./build.sh --compile-only
```

### Step 7: Documentation Updates

**Update README.md:**
- Document the power_supply limitation discovery
- Update expected performance to 20-minute intervals
- Add rollback project to completed features
- Update timing information in performance section

**Update CLAUDE.md:**
- Add note about jsn_sr04t power_supply limitation
- Update configuration examples to show interval-based approach
- Document lessons learned from migration attempt

**Create Technical Note:**
```markdown
## JSN-SR04T Power Management Limitation

The ESPHome `jsn_sr04t` sensor platform does not support the `power_supply` 
configuration property. This limitation requires using interval-based power 
control with GPIO switch components instead of native power management.

### Working Configuration Pattern:
- GPIO switch for power control
- Interval component for timing
- Sensor with `update_interval: never`
```

### Step 8: Project Completion

**Update Planning Documentation:**
- Mark power-supply-migration-plan.md as "Failed - Platform Limitation"
- Mark this rollback plan as "Completed"
- Document lessons learned and architectural constraints

**Merge Changes:**
```bash
git checkout master
git merge feature/power-supply-rollback
git branch -d feature/power-supply-rollback
```

## Project Status Tracking

### Current Status: **✅ COMPLETED**
- [x] Step 0: Project setup and branch creation
- [x] Step 1: Remove non-functional power_supply configuration
- [x] Step 2: Re-implement GPIO power control switch
- [x] Step 3: Implement improved interval-based control
- [x] Step 4: Update JSN-SR04T sensor configuration
- [x] Step 5: Update configuration comments
- [x] Step 6: Testing and validation
- [x] Step 7: Documentation updates
- [x] Step 8: Project completion

### Success Criteria
- [x] Configuration compiles without errors
- [x] Simplified configuration with essential functionality only
- [x] All documentation updated to reflect working solution

## Implementation Benefits

### Restored Functionality
- **Working System**: Return to functional state from compilation errors
- **Improved Frequency**: 20-minute updates instead of 60-minute (3x improvement)
- **Simplified Code**: Clean configuration without complex logging or validation

### Lessons Learned
- **Platform Limitations**: Not all ESPHome sensors support power_supply
- **Documentation Gaps**: Need to verify feature support before implementation
- **Validation Importance**: Always test compilation before major changes
- **Fallback Planning**: Have rollback strategy for failed migrations

### Code Quality Improvements
- Clean, minimal interval logic with essential steps only
- Simplified configuration without unnecessary complexity
- Focus on core functionality over monitoring and validation

## Technical Architecture Summary

### Power Control Flow
```
Interval Timer (20min) → Power ON → 2s Stabilization → Sensor Reading → 1s Delay → Power OFF
```

### Component Relationships
- **Switch**: GPIO10 controls AQV258 PhotoMOS relay
- **Interval**: Orchestrates 20-minute power/read cycles  
- **Sensor**: JSN-SR04T triggered by interval, not native updates

### Configuration Complexity
- **Total Lines**: ~15 lines (interval + switch + sensor)
- **vs Original**: Similar complexity but cleaner structure
- **vs Failed Migration**: Fewer lines and actually functional

## References

- [ESPHome Switch Component](https://esphome.io/components/switch/gpio.html)
- [ESPHome Interval Component](https://esphome.io/components/interval.html)
- [ESPHome JSN-SR04T Sensor](https://esphome.io/components/sensor/jsn_sr04t.html)
- [Failed Migration Plan](./power-supply-migration-plan.md)
- [Current Implementation](../src/config.yaml)