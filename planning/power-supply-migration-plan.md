# Power Supply Migration Implementation Plan

## Overview

This document outlines the migration from manual interval-based sensor power control to ESPHome's native `power_supply` component for JSN-SR04T sensor power management. This change will simplify the configuration, improve reliability, and leverage ESPHome's built-in power management capabilities.

## Current Implementation Analysis

### Current Architecture
- **Power Control**: Manual GPIO switch (`sensor_power_control`) on GPIO10
- **Triggering**: `interval` component triggers readings every 1 hour
- **Timing**: Manual power-on → 2s delay → 3 readings → 1s delay → power-off
- **Sensor Updates**: `update_interval: never` (controlled by interval)

### Current Configuration Elements
```yaml
switch:
  - platform: gpio
    pin: GPIO10
    id: sensor_power_control
    inverted: true
    internal: true

interval:
  - interval: 1h
    then:
      - switch.turn_on: sensor_power_control
      - delay: 2s
      - component.update: raw_distance_sensor
      # ... (repeat readings)
      - switch.turn_off: sensor_power_control

sensor:
  - platform: jsn_sr04t
    update_interval: never
```

## Target Implementation Requirements

### New Architecture
- **Power Control**: ESPHome `power_supply` component 
- **Triggering**: Native sensor `update_interval: 20min`
- **Timing**: Automatic power management with configurable timing
- **Power Duration**: 2s pre-read + reading time + 1s post-read

### Key Changes
1. **Remove `interval` component** - no longer needed for triggering
2. **Remove manual `switch` component** - replaced by `power_supply`
3. **Set sensor `update_interval: 20min`** - sensor manages its own timing
4. **Add `power_supply` configuration** with proper timing

## Implementation Steps

### Step 0: Project Setup and Branch Management

**Create Implementation Branch:**
```bash
git checkout -b feature/power-supply-migration
```

**Project Status Tracking:**
- Update project status to "In Progress" in this planning document
- Track completion of each implementation step
- Commit changes after each logical unit of work
- Update all documentation to reflect new implementation

### Step 1: Add Power Supply Component

Create a new `power_supply` component to manage JSN-SR04T power:

```yaml
power_supply:
  - id: jsn_sr04t_power
    pin: GPIO10
    inverted: true  # For AQV258 PhotoMOS (HIGH=ON, LOW=OFF)
    enable_time: 2000ms  # Power-on stabilization time
    keep_on_time: 1000ms # Keep power after last sensor stops
```

**Key Configuration Details:**
- `id: jsn_sr04t_power` - Unique identifier for the power supply
- `pin: GPIO10` - Same pin currently used for manual control
- `inverted: true` - Maintain compatibility with AQV258 PhotoMOS logic
- `enable_time: 2000ms` - Allow 2 seconds for sensor stabilization before reading
- `keep_on_time: 1000ms` - Keep power for 1 second after sensor reading completes

### Step 2: Update JSN-SR04T Sensor Configuration

Modify the existing sensor configuration to use power supply and native updates:

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
    update_interval: 20min  # Changed from 'never' to '20min'
    power_supply: jsn_sr04t_power  # Link to power supply component
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

**Key Configuration Changes:**
- `update_interval: 20min` - Sensor now updates every 20 minutes automatically
- `power_supply: jsn_sr04t_power` - Links sensor to power supply for automatic management
- Remove dependency on manual triggering

### Step 3: Remove Obsolete Components

Remove the following components that are no longer needed:

1. **Remove `switch` component:**
```yaml
# DELETE: Manual power control switch
switch:
  - platform: gpio
    pin: GPIO10
    id: sensor_power_control
    # ... entire switch config
```

2. **Remove `interval` component:**
```yaml
# DELETE: Manual interval triggering
interval:
  - interval: 1h
    then:
      # ... entire interval logic
```

### Step 4: Update Documentation Comments

Update relevant comments in the configuration:

```yaml
# JSN-SR04T with automatic power management via power_supply
sensor:
  # Raw distance sensor with native 20-minute updates and power management
  - platform: jsn_sr04t
    # ... sensor config with power_supply reference
```

### Step 5: Documentation Updates

After completing the code changes, update all project documentation:

**Update README.md:**
1. Update "Expected Performance" section to reflect 20-minute intervals
2. Add power supply migration to completed features
3. Update planning documents section to include this implementation
4. Add new planning document reference to the planning documents list

**Update CLAUDE.md:**
1. Modify configuration examples to show power_supply usage
2. Update timing information in performance notes
3. Update any references to interval-based triggering

**Commit Documentation Updates:**
```bash
git add README.md CLAUDE.md
git commit -m "Update documentation for power_supply implementation"
```

### Step 6: Project Completion and Integration

**Mark Project as Completed:**
1. Update project status in this document to "Completed"
2. Add completion date and summary
3. Update README.md planning documents section

**Merge to Main Branch:**
```bash
git checkout master
git merge feature/power-supply-migration
git branch -d feature/power-supply-migration
```

**Final Commit:**
```bash
git add planning/power-supply-migration-plan.md README.md
git commit -m "Complete power supply migration project

- Mark project as completed in planning document
- Update README.md with completed project reference
- All implementation and documentation updates merged successfully"
```

## Project Status Tracking

### Current Status: **Completed**
- [x] Step 0: Project setup and branch creation
- [x] Step 1: Add power_supply component
- [x] Step 2: Update JSN-SR04T sensor configuration  
- [x] Step 3: Remove obsolete components
- [x] Step 4: Update configuration comments
- [x] Step 5: Documentation updates (README.md, CLAUDE.md)
- [x] Step 6: Project completion and integration

### Project Completed: September 11, 2025
✅ Successfully migrated from interval-based manual power control to native ESPHome power_supply component
✅ Implemented 20-minute automatic sensor updates with proper power management  
✅ Reduced configuration complexity by removing 15+ lines of manual timing logic
✅ All documentation updated to reflect new implementation

### Completion Criteria
- ✅ All code changes implemented and tested
- ✅ All documentation updated to reflect new implementation
- ✅ Changes committed after each logical unit
- ✅ Project status tracked throughout implementation
- ✅ Final merge to master branch completed
- ✅ Project marked as completed in planning documents

## Implementation Validation

### Pre-Implementation Testing
1. **Backup Current Configuration**: Save working `src/config.yaml`
2. **Document Current Behavior**: Record existing timing and power patterns
3. **Verify Hardware**: Confirm AQV258 PhotoMOS operates correctly with current logic

### Post-Implementation Testing
1. **Power Timing Verification**: Monitor GPIO10 to confirm proper power-on/off timing
2. **Reading Frequency**: Verify 20-minute update intervals are maintained
3. **Sensor Stability**: Confirm readings remain accurate with new power management
4. **Power Consumption**: Validate expected power-off periods between readings

### Testing Commands
```bash
# Monitor device logs for power supply events
./monitor.sh

# Check timing with ESPHome logs
# Look for power_supply enable/disable events
# Verify sensor reading timestamps
```

## Expected Behavior Changes

### Timing Improvements
- **Previous**: Manual 1-hour intervals with fixed 3-reading bursts
- **New**: Consistent 20-minute intervals with single readings per cycle

### Power Management
- **Previous**: Manual GPIO control with explicit delays
- **New**: ESPHome automatic power management with guaranteed timing

### Code Simplification
- **Removed Lines**: ~15 lines of interval and switch configuration
- **Added Lines**: ~5 lines of power_supply configuration
- **Net Reduction**: ~10 lines of configuration code

## Rollback Plan

If issues arise during implementation:

1. **Immediate Rollback**: Restore backed-up `src/config.yaml`
2. **Partial Rollback**: Keep power_supply but restore interval triggering temporarily
3. **Hardware Verification**: Test AQV258 PhotoMOS logic levels if power issues occur

## Benefits of Migration

### Reliability Improvements
- Native ESPHome power management reduces custom logic complexity
- Automatic timing eliminates manual delay management
- Built-in error handling for power supply failures

### Maintenance Benefits
- Fewer custom components to maintain
- Standard ESPHome patterns for easier troubleshooting
- Cleaner configuration with better separation of concerns

### Performance Optimization
- More frequent updates (20min vs 60min) for better monitoring
- Consistent single readings vs burst readings
- Reduced power cycling complexity

## References

- [ESPHome Power Supply Component](https://esphome.io/components/power_supply.html)
- [ESPHome JSN-SR04T Sensor](https://esphome.io/components/sensor/jsn_sr04t.html)
- [Current Implementation](../src/config.yaml)
- [AQV258 PhotoMOS Documentation](../docs/WIRING_SCHEMATICS.md)