# Wiring — UART (Mode 2 with 120kΩ on R27)

**Bidirectional UART:** sensor **TX → ESP RX** and **ESP TX → sensor RX**. **Solder a 120kΩ resistor on pad R27** to enable UART **Mode 2**. Consult your module’s silkscreen (often labeled **R27 / MODE / M1**).

**Recommended pins**

* Sensor **TX** → **ESP RX (GPIO20)** via level shifter
* ESP **TX (GPIO21)** → **Sensor RX** via level shifter
* Power & ground: **VCC → 5V/VBUS**, **GND → GND**

**Connections**

* JSN‑SR04T **VCC** → ESP **5V/VBUS**
* JSN‑SR04T **GND** → ESP **GND**
* JSN‑SR04T **TX** → (HV) **Level Shifter HV1** → **LV1** → **GPIO20 (RX)**
* JSN‑SR04T **RX** ← (HV) **Level Shifter HV2** ← **LV2** ← **GPIO21 (TX)**

> **Tip:** Keep cable from control board to transducer head short to minimize noise. Mount sensor head facing straight down for level sensing.

**ASCII Wiring Diagram**

```
   JSN-SR04T Module             Level Shifter                 ESP32-C3 Super Mini
   -----------------            --------------                -------------------
   VCC (5V) ------------------> HV 5V     LV 3V3 <---------- 3V3 (reference)
   GND -----------------------> GND       GND   <----------> GND

   TX  -----------------------> HV1  -->  LV1  ------------> GPIO20 (RX)
   RX  <----------------------- HV2  <--  LV2  <------------ GPIO21 (TX)

   ESP32-C3 5V (VBUS) --------> VCC
   ESP32-C3 GND --------------> GND
```
