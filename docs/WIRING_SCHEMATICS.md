# Wiring — UART (Mode 2 with 120kΩ on R27)

**Bidirectional UART:** sensor **TX → ESP RX** and **ESP TX → sensor RX**. **Solder a 120kΩ resistor on pad R27** to enable UART **Mode 2**. Consult your module’s silkscreen (often labeled **R27 / MODE / M1**).

**Recommended pins**

* Sensor **TX** → **ESP RX (GPIO20)** via level shifter
* ESP **TX (GPIO21)** → **Sensor RX** via level shifter
* Power & ground: **VCC → 5V/VBUS**, **GND → GND**

**Connections**

* JSN‑SR04T **VCC** → **SSR Output** → ESP **5V/VBUS**
* JSN‑SR04T **GND** → ESP **GND**  
* JSN‑SR04T **TX** → (HV) **Level Shifter HV1** → **LV1** → **GPIO20 (RX)**
* JSN‑SR04T **RX** ← (HV) **Level Shifter HV2** ← **LV2** ← **GPIO21 (TX)**
* **SSR Control Input** ← **GPIO10** (via current limiting resistor if needed)
* **SSR Input** ← ESP **5V/VBUS**

> **Tip:** Keep cable from control board to transducer head short to minimize noise. Mount sensor head facing straight down for level sensing.

**ASCII Wiring Diagram**

```
   JSN-SR04T Module             SSR + Level Shifter            ESP32-C3 Super Mini
   -----------------            --------------------            -------------------
   VCC (5V) --------> SSR OUT   HV 5V     LV 3V3 <---------- 3V3 (reference)
   GND -----------------------> GND       GND   <----------> GND

   TX  -----------------------> HV1  -->  LV1  ------------> GPIO20 (RX)
   RX  <----------------------- HV2  <--  LV2  <------------ GPIO21 (TX)

   SSR Control Input <------------------------------------ GPIO10
   SSR Input <------------ ESP32-C3 5V (VBUS)
   ESP32-C3 GND --------------> GND
```

## SSR Power Control Integration

**Solid State Relay Requirements:**
- Input: 3-32VDC control voltage (3.3V compatible)
- Output: Rated for JSN-SR04T (5V, <50mA)
- Low-trigger type preferred (ON when control pin is LOW)
- Isolation between control and power circuits

**Additional Components:**
- **Current limiting resistor** (220Ω-1kΩ) between GPIO10 and SSR control input (optional, check SSR specs)
- **Pull-up resistor** (10kΩ) on SSR control input for defined OFF state (optional)

**Power Control Sequence:**
1. GPIO10 goes LOW → SSR turns ON → JSN-SR04T powered
2. 2-second stabilization delay
3. 3 burst readings with 2s intervals
4. GPIO10 goes HIGH → SSR turns OFF → JSN-SR04T unpowered
