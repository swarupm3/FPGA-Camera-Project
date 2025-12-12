# FPGA Real-Time Camera Pipeline on Urbana Spartan-7

This project implements a fully hardware-driven real-time camera pipeline on the **Urbana Spartan-7 FPGA board**, using an **OV7670 camera sensor**, on-chip BRAM buffering, RTL pixel processing, and **HDMI output**.  

The system runs entirely in **SystemVerilog**, processes one pixel per clock, and requires **no SOC**.

---

## Table of Contents
- [Overview](#overview)
- [Hardware Used](#hardware-used)
- [Operation Guide](#operation-guide)


---

## Overview

This design receives pixel data from an **OV7670 CMOS camera**, configures the sensor via I2C/SCCB, captures incoming frames using BRAM, optionally applies image-processing functions (brightness, edge detection, skin detection), and outputs the processed image over **HDMI** in real time.

Features include:

- Custom I2C configuration FSM    
- Dual-port BRAM frame buffering  
- YUV422 color formatting with grayscale conversion using 21-bits of luminance 
- HDMI TMDS encoding (640×480 @ 60Hz) 
- Brightness control using on-board potentiometer (XADC)  
- Edge/skin detection toggles  
- User adjustable skin detection thresholds  


---

## Hardware Used

- Urbana **Spartan-7 FPGA board**  
- **OV7670** camera module  
- HDMI output port  
- On-board potentiometer (XADC → brightness control)  
- User switches & buttons for start/reset/detection toggles  
- 20x Jumper Wires
- 2x 4.7 KOhm Resistors
- Breadboard

---

##  Operation Guide

This section describes what buttons to press and how to operate the system on the Urbana board.

###  1. Start the Camera (`start_fsm`)
**Button J2 — Pushbutton / switch**

Press to:

- Initialize OV7670 via I2C/SCCB  
- Write all required camera registers  
- Start VSYNC/HREF/PCLK capture  
- Begin real-time processing + HDMI output  

Repeated presses safely restart the camera sequence.

---

###  2. Reset the System (`reset`)
**Button J1**

Press to:

- Reset HDMI timing  
- Clear pipeline registers  
- Reset BRAM address counters  
- Reset skin-detection bounding box logic  

Does *not* reconfigure the camera unless `start_fsm` is pressed again.

---

### 3. Adjust Brightness (Potentiometer → XADC)

Potentiometer pins:

- **VP = J10**  
- **VN = K9**

Rotation:

- Clockwise → **increases brightness**  
- Counter-clockwise → **decreases brightness**  


### 4. Skin Detection Control (`sw[15:0]`)

Skin detection is controlled entirely through the Urbana board’s switches.

There are two parts:

- `sw[15]` — **Skin detection enable/disable toggle**
- `sw[14:0]` — **15-bit threshold for skin-detection sensitivity**

These allow real-time tuning without reprogramming the FPGA.

---

### `sw[15]` — Skin Detection Toggle

- **`sw[15] = 0`** → Skin detection **OFF**  
- **`sw[15] = 1`** → Skin detection **ON**

When enabled, the camera generates a red bounding box on skin-colored regions

---

### `sw[14:0]` — Skin Detection Threshold

Switches **0 through 14** combine to form a 15-bit threshold value used by the skin-detection comparator.

This determines how strict or lenient the detector is:

- **Lower threshold → stricter detection**  
  - Fewer pixels qualify as skin  
- **Higher threshold → more permissive**  
  - More pixels qualify as skin  

Threshold updates apply immediately on the next pixel clock.

---

### 5. Edge Detection Toggle (Button H2)

The **leftmost button (mapped to pin H2)** controls the edge-detection mode in the image-processing pipeline.

- **Button H2 = 0** → Edge detection OFF  
- **Button H2 = 1** → Edge detection ON  

When enabled, the pipeline highlights edges by emphasizing rapid pixel-intensity changes.  
The effect updates immediately every pixel clock cycle, with no added frame delay.

This control lets you visually inspect object boundaries and verify that the capture + processing pipeline is functioning correctly.











