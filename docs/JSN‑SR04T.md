# JSN‑SR04T — Ultrasonic Module

## Specifications

## Power requirements

* **Operating voltage:** 5 V (recommended)
* **Logic levels:** referenced to 5 V (sensor TX outputs 5 V)
* **3.3 V operation:** sometimes works, but with reduced range and unstable readings. Not recommended. Always power at 5 V and level‑shift signals to the ESP32‑C3.

| Spec           | Value                                                                                                                          |
| -------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| **Range**      | **25 cm –600 cm** typical (blind zone ≈ 20–25 cm). Some v3.0 datasheets list **21–600 cm**.                                    |
| **Accuracy**   | Datasheet claim: **up to 3 mm**. Practical expectation: **±5–15 mm** in the 30–200 cm band with stable mounting and filtering. |
| **Resolution** | **1 mm** (UART frame step).                                                                                                    |
| **Units**      | **Module (UART):** millimeters (per frame). **ESPHome output:** centimeters (see YAML `unit_of_measurement: "cm"`).            |

> Notes: Actual performance depends on surface (ripples/foam), temperature, and mounting angle.

# Notes

* JSN‑SR04T typical range is \~25–600 cm; performance depends on surface and mounting.
* For concrete tanks or narrow shafts, echo multipath may require extra filtering or averaging.


## Modes

The device supports multiple modes that govern how it communicates and how readings are triggered. Modes are selected via a resistor soldered to **pad R27**.

## Default mode — Pulse/Echo

* Default settings - pad R27 is open (no resistor connected)
* Reading triggered by a pulse on **TRIG**
* **ECHO** pulse width equals time from trigger to echo received

## Mode 1 — UART, continuous reading

* Activated by adding **47 kΩ** resistor to **R27**
* Serial communication (UART): **9600, 8N1**
* Automatic reading every \~100 ms

## Mode 2 — UART, triggered reading

* Activated by adding **120 kΩ** resistor to **R27**
* Serial communication (UART): **9600, 8N1**
* Reading triggered by sending the command `0x55`

## Power Control Integration

**Important:** During testing, the JSN-SR04T sensor was observed to occasionally get stuck producing the same value continuously, not reflecting actual water level changes. Unlike the ESP32-C3 which can be restarted programmatically, the JSN-SR04T has no software reset capability.

### Solid State Relay (SSR) Power Control

To ensure reliable operation, the sensor power is controlled via a solid state relay connected to **GPIO10**:

**Power Control Sequence:**
1. **Power On**: GPIO10 → LOW → SSR ON → JSN-SR04T powered
2. **Stabilization**: 2-second delay for sensor initialization  
3. **Readings**: 3 burst measurements with 2s intervals
4. **Power Off**: GPIO10 → HIGH → SSR OFF → JSN-SR04T unpowered

**Benefits:**
- **Reliability**: Clears any stuck internal states by power cycling
- **Power Savings**: ~95% reduction in power consumption (sensor only on during readings)
- **Hardware Longevity**: Reduced thermal stress and component wear

### SSR Requirements

- **Input**: 3-32VDC control voltage (3.3V ESP32-C3 compatible)
- **Output**: Rated for JSN-SR04T power (5V, <50mA)
- **Type**: Low-trigger preferred (ON when control pin is LOW)
- **Isolation**: Galvanic isolation between control and power circuits

### Timing Considerations

**Sensor Initialization Time**: JSN-SR04T requires ~2 seconds after power-on to stabilize and provide accurate readings. The ESPHome configuration includes this delay automatically.

**Reading Completion**: Allow 1-second delay after final reading before power-off to ensure UART communication completes properly.
