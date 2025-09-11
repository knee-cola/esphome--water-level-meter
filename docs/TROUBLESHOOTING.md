# Troubleshooting

## General Issues

* **No readings / nan:** verify **120kΩ on R27** (Mode 2), confirm UART baud (**9600**), check both level-shifter channels (TX↔RX), and wiring/ground.
* **Noisy readings:** add a `median` filter (as in YAML), shield/shorten sensor cable, avoid mounting near walls/angles.
* **Wrong distance:** set `tank_depth_cm` correctly and ensure the sensor points perpendicular to the liquid surface.
* **UART mode not working:** recheck the **R27** solder, the RX/TX pin numbers (GPIO20/GPIO21), and that the sensor **TX/RX** are on the correct HV channels of the level shifter.

## SSR Power Control Issues

### Sensor Not Responding After Power Cycle

**Symptoms:** No readings after SSR power control implementation, sensor appears dead.

**Troubleshooting:**
1. **Check SSR wiring**: Verify GPIO10 → SSR control input connection
2. **Test SSR operation**: Use multimeter to confirm SSR switches 5V to JSN-SR04T VCC
3. **Verify SSR type**: Low-trigger SSRs turn ON when control pin is LOW (inverted: true in config)
4. **Check power supply**: Ensure ESP32-C3 5V rail can handle JSN-SR04T + SSR control current
5. **Test manual control**: Use Home Assistant to manually toggle "JSN-SR04T Power Control" switch

### Stuck Sensor Values

**Symptoms:** Sensor reports same value continuously, not reflecting actual water level changes.

**Root Cause:** JSN-SR04T internal controller in bad state (this is why SSR power control was implemented).

**Solution:** The SSR power cycling should automatically resolve this. If issue persists:
1. **Increase stabilization delay**: Change `delay: 2s` to `delay: 5s` in interval configuration
2. **Check SSR operation**: Verify complete power-off between cycles
3. **SSR leakage**: Some cheap SSRs have small leakage current - use higher quality SSR

### Power Control Timing Issues

**Symptoms:** Intermittent readings, sensor sometimes doesn't respond.

**Troubleshooting:**
1. **Stabilization time**: JSN-SR04T needs 2+ seconds after power-on to initialize
2. **Reading completion**: Ensure 1-second delay before power-off to complete UART communication
3. **Power supply settling**: Add small capacitor (100µF) across JSN-SR04T VCC/GND if power rail is noisy

### SSR Selection Problems

**Wrong SSR Type:**
- **High-trigger SSR**: Requires `inverted: false` in switch configuration
- **Low-trigger SSR**: Requires `inverted: true` (recommended, current config)

**Insufficient SSR Rating:**
- **Input**: Must handle 3.3V control signal (or use current limiting resistor)
- **Output**: Must handle 5V, 50mA for JSN-SR04T

**SSR Failure Detection:**
1. **Control signal test**: Measure voltage at GPIO10 (should toggle 0V/3.3V)
2. **SSR output test**: Measure voltage at JSN-SR04T VCC (should toggle 0V/5V)
3. **Current test**: Measure current through SSR output (should be <50mA when sensor active)
