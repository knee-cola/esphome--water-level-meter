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
