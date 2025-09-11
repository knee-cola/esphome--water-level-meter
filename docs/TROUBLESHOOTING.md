# Troubleshooting

* **No readings / nan:** verify **120kΩ on R27** (Mode 2), confirm UART baud (**9600**), check both level-shifter channels (TX↔RX), and wiring/ground.
* **Noisy readings:** add a `median` filter (as in YAML), shield/shorten sensor cable, avoid mounting near walls/angles.
* **Wrong distance:** set `tank_depth_cm` correctly and ensure the sensor points perpendicular to the liquid surface.
* **UART mode not working:** recheck the **R27** solder, the RX/TX pin numbers (GPIO20/GPIO21), and that the sensor **TX/RX** are on the correct HV channels of the level shifter.
