# Home Assistant Integration

## Automatic Entity Discovery

With the ESPHome integration, the following entities will appear automatically once the device comes online:

### Sensor Entities
- **Raw Distance**: Distance from sensor to water surface (meters)
- **Water Tank Level**: Calculated water level percentage (0-100%)
- **Water Volume**: Calculated water volume in liters
- **WiFi Signal**: Device connectivity strength (dBm)
- **Uptime**: Device runtime since last boot

### Binary Sensor Entities  
- **Low Water Alert**: Triggers when water level drops below configured threshold
- **Status**: Device online/offline connectivity status

### Configuration Entities
- **Distance When Full**: Tank calibration - sensor distance when tank is full
- **Distance When Empty**: Tank calibration - sensor distance when tank is empty  
- **Tank Area**: Physical tank cross-sectional area in m²
- **Low Water Alert Threshold**: Percentage threshold for low water alerts

### Power Control Entity (Internal)
- **JSN-SR04T Power Control**: SSR control switch (hidden from UI, internal: true)

## Power Control Management

The **JSN-SR04T Power Control** switch is marked as `internal: true` and will not appear in the Home Assistant UI by default. This prevents accidental manual control that could interfere with the automated hourly power cycling.

### Manual Override (Advanced)

If needed for troubleshooting, you can expose the power control switch by temporarily removing the `internal: true` line from the ESPHome configuration. This allows manual testing of the SSR and sensor power control.

**Use cases for manual override:**
- Testing SSR operation during initial setup
- Debugging power control issues
- Taking immediate sensor readings outside the hourly schedule

**Important:** Remember to restore `internal: true` after troubleshooting to prevent accidental interference with automated operation.

## Dashboard Visualization

Use these Home Assistant cards to visualize water levels:

### Recommended Cards
- **Gauge Card**: Real-time water level percentage display
- **History Graph**: Water level trends over time
- **Entity Card**: Current water volume in liters
- **Alert Card**: Low water warning display

### Example Dashboard Configuration

```yaml
type: vertical-stack
cards:
  - type: gauge
    entity: sensor.water_tank_level
    name: Water Tank Level
    min: 0
    max: 100
    severity:
      green: 50
      yellow: 25
      red: 0
  
  - type: history-graph
    entities:
      - sensor.water_tank_level
    hours_to_show: 168  # 1 week
    
  - type: entities
    entities:
      - sensor.water_volume
      - binary_sensor.low_water_alert
      - sensor.wifi_signal
```

## Automation Examples

### Low Water Notification

```yaml
automation:
  - alias: "Water Tank Low Alert"
    trigger:
      - platform: state
        entity_id: binary_sensor.low_water_alert
        to: "on"
    action:
      - service: notify.mobile_app
        data:
          title: "Water Tank Low"
          message: "Water level is below {{ states('number.low_water_alert_threshold') }}%"
```

### Daily Water Usage Report

```yaml
automation:
  - alias: "Daily Water Usage"
    trigger:
      - platform: time
        at: "06:00:00"
    action:
      - service: notify.mobile_app
        data:
          title: "Water Usage Report"
          message: "Current level: {{ states('sensor.water_tank_level') }}% ({{ states('sensor.water_volume') }}L)"
```
