# Developer Guide — Code Architecture

Quick reference for developers who want to understand, modify, or extend the firmware.

## Hardware Overview

- **MCU:** DP32G030 — ARM Cortex-M0, 48MHz, 64KB Flash, 16KB RAM
- **RF Chip:** BK4819 — wideband transceiver IC, controlled via SPI registers
- **FM Chip:** BK1080 — FM broadcast receiver IC (76-108 MHz)
- **Display:** ST7565 — 128x64 monochrome LCD, SPI interface
- **EEPROM:** 8KB configuration storage via I2C
- **Flash layout:** 60KB usable for firmware (4KB reserved for bootloader)
- **Stack:** 128 bytes minimum, grows downward from 0x20004000

## Source Tree

```
├── main.c              Main entry, boot sequence, main loop
├── init.c              Hardware initialization (clocks, GPIO, peripherals)
├── start.S             ARM Cortex-M0 startup, vector table, reset handler
├── firmware.ld         Linker script (60KB flash, 16KB RAM)
├── scheduler.c         SysTick ISR: 10ms tick, 500ms tick, countdown timers
├── radio.c             Radio core: channel config, modulation, TX/RX setup
├── settings.c          EEPROM read/write for all persistent settings
├── frequencies.c       Frequency band tables, TX allow lists, step values
├── functions.c         State machine (FOREGROUND, RECEIVE, TRANSMIT, etc.)
├── am_fix.c            AM demodulator AGC fix (software gain control)
├── audio.c             Audio path control, beep generation, DTMF tones
├── board.c             Board-level init (GPIO pins, ADC, peripherals)
├── misc.c              Global variables, shared state
├── font.c              Font bitmap data (3x5, small, small bold, big)
├── bitmaps.c           UI icon bitmaps
├── dcs.c               DCS/CTCSS tone code tables
│
├── app/                Application logic
│   ├── app.c           Main application dispatcher, key handling, timeslices
│   ├── main.c          Main VFO screen key processing
│   ├── menu.c          Menu system (display, accept, navigate)
│   ├── spectrum.c      Spectrum analyzer (scan, draw, peak hold)
│   ├── scanner.c       Frequency/channel scanner
│   ├── fm.c            FM broadcast radio application
│   ├── dtmf.c          DTMF calling system (contacts, groups)
│   ├── action.c        Side button / long-press actions
│   ├── generic.c       Shared key handlers (PTT, EXIT, etc.)
│   ├── flashlight.c    Flashlight toggle logic
│   ├── chFrScanner.c   Channel/frequency scanner helpers
│   ├── common.c        Common app utilities
│   └── uart.c          UART command handler (PC communication)
│
├── driver/             Hardware abstraction layer
│   ├── bk4819.c        BK4819 RF transceiver driver (SPI register access)
│   ├── bk4819-regs.h   BK4819 register definitions
│   ├── bk1080.c        BK1080 FM receiver driver
│   ├── st7565.c        ST7565 LCD driver (SPI, framebuffer blit)
│   ├── eeprom.c        EEPROM I2C read/write
│   ├── gpio.c          GPIO pin control
│   ├── spi.c           SPI bus driver
│   ├── i2c.c           I2C bus driver
│   ├── uart.c          UART hardware driver
│   ├── adc.c           ADC for battery voltage
│   ├── aes.c           AES encryption (firmware packing)
│   ├── keyboard.c      Key matrix scanning
│   ├── backlight.c     LCD backlight PWM control
│   ├── crc.c           CRC calculation
│   ├── flash.c         Internal flash read/write
│   ├── system.c        System clock, delay functions
│   └── systick.c       SysTick timer setup
│
├── ui/                 Display rendering
│   ├── main.c          Main screen (frequency, RSSI, channel info)
│   ├── menu.c          Menu screen renderer
│   ├── status.c        Status bar (battery, icons, mode indicators)
│   ├── scanner.c       Scanner screen
│   ├── fmradio.c       FM radio screen
│   ├── battery.c       Battery icon drawing
│   ├── helper.c        Pixel/string drawing primitives
│   ├── inputbox.c      Frequency input box
│   ├── welcome.c       Boot splash screen
│   └── ui.c            UI dispatcher (routes to correct screen)
│
├── helper/             Utility modules
│   ├── battery.c       Battery voltage to percentage conversion
│   └── boot.c          Boot key detection, mode selection
│
├── bsp/dp32g030/       MCU peripheral register definitions
│   ├── gpio.h          GPIO registers
│   ├── spi.h           SPI registers
│   ├── uart.h          UART registers
│   ├── flash.h         Flash controller registers
│   ├── aes.h           AES peripheral registers
│   ├── dma.h           DMA registers
│   ├── saradc.h        SAR ADC registers
│   ├── syscon.h        System control registers
│   ├── pmu.h           Power management registers
│   ├── irq.h           Interrupt definitions
│   ├── portcon.h       Port configuration registers
│   ├── pwmplus.h       PWM registers
│   └── crc.h           CRC peripheral registers
│
└── external/
    ├── printf/         Lightweight printf implementation
    └── CMSIS_5/        ARM CMSIS headers for Cortex-M0
```

## Execution Flow

### Boot Sequence

```
start.S (HandlerReset)
  → init.c (BSS clear, data copy)
    → main.c Main()
      → board.c BOARD_Init() — GPIO, SPI, I2C, UART, ADC
      → settings.c SETTINGS_InitEEPROM() — load all settings from EEPROM
      → radio.c RADIO_ConfigureChannel() — configure VFOs
      → Enter main loop
```

### Main Loop (main.c)

The firmware runs a cooperative (non-preemptive) main loop driven by SysTick:

```
while (true) {
    APP_Update();           // process pending events (key, RX, scan)

    if (gNextTimeslice) {           // every 10ms
        APP_TimeSlice10ms();        // RSSI update, AM fix, DTMF decode
        
        if (gNextTimeslice_500ms) { // every 500ms
            APP_TimeSlice500ms();   // battery check, power save, dual watch
        }
    }
}
```

### Scheduler (scheduler.c)

SysTick fires every 10ms. The ISR:
- Sets `gNextTimeslice = true` every 10ms
- Sets `gNextTimeslice_500ms = true` every 500ms (every 50th tick)
- Decrements all countdown timers (battery save, TX timeout, scan delay, etc.)

No RTOS. No threads. Everything is event-driven through flags and counters.

### State Machine (functions.c)

The radio operates in one of these states:

```
FUNCTION_FOREGROUND  — idle, scanning, or waiting
FUNCTION_RECEIVE     — actively receiving a signal
FUNCTION_TRANSMIT    — transmitting
FUNCTION_POWER_SAVE  — low power mode (periodic wake)
```

State transitions happen through `FUNCTION_Select()`.

## Key Subsystems

### BK4819 RF Chip (driver/bk4819.c)

All RF operations go through SPI register writes to the BK4819. Key operations:

- **Frequency:** `BK4819_SetFrequency(freq)` — sets VCO
- **Modulation:** `BK4819_SetAF(type)` — REG_47, selects FM/AM/USB/RAW demodulator
- **Bandwidth:** `BK4819_SetFilterBandwidth()` — REG_43, RF and AF filter widths
- **AGC:** `BK4819_InitAGC()` / `BK4819_SetAGC()` — REG_7E, REG_10-14 gain tables
- **RSSI:** `BK4819_GetRSSI()` — reads current signal strength
- **TX:** `BK4819_SetupPowerAmplifier()` — PA bias and gain
- **Squelch:** configured via multiple registers for RSSI/noise/glitch thresholds

### Modulation (radio.c)

`RADIO_SetModulation()` switches between modes by configuring BK4819:

| Mode | AF Type | AFC | AGC |
|---|---|---|---|
| FM | BK4819_AF_FM (1) | Enabled | Hardware AGC |
| AM | BK4819_AF_AM (7) | Disabled | AM Fix software AGC |
| USB | BK4819_AF_BASEBAND2 (5) | Disabled | Hardware AGC |

### AM Fix (am_fix.c)

Software AGC that replaces the BK4819's inadequate AM gain control:

1. Reads RSSI every 10ms via `AM_fix_10ms()`
2. Averages over 4 samples (sliding window)
3. Compares to target RSSI (-89dBm)
4. Adjusts REG_13 (LNA Short + LNA + Mixer + PGA gain) using a sorted gain table
5. Adaptive hysteresis prevents gain hunting
6. Slow gain recovery prevents audio pumping

### Display (ui/ + driver/st7565.c)

- **Framebuffer:** `gFrameBuffer[7][128]` — 7 rows × 128 columns = 896 bytes (partial screen)
- **Status line:** `gStatusLine[128]` — separate top row buffer
- **Rendering:** modules write to framebuffer, then `ST7565_BlitFullScreen()` sends via SPI
- **Fonts:** 3x5 (tiny), small (7px), small bold (7px), big (variable width)
- **Drawing:** `UI_DrawPixelBuffer()` for pixel-level access

### Spectrum Analyzer (app/spectrum.c)

Self-contained module with its own scan-render-listen loop:

1. **Scan:** sweep frequency range, read RSSI at each step into `rssiHistory[128]`
2. **Render:** draw bars from rssiHistory, peak hold trace, trigger level, frequency labels
3. **Listen:** when peak exceeds trigger, tune to peak and enable audio
4. **States:** SPECTRUM (scanning), STILL (single frequency), FREQ_INPUT (keyboard entry)

### EEPROM Layout (settings.c)

8KB EEPROM stores all persistent data:
- Channel memories (frequency, CTCSS, power, name)
- VFO settings
- Calibration data (power levels, battery, frequency offset)
- FM radio presets
- DTMF contacts

Read via `EEPROM_ReadBuffer()`, write via `EEPROM_WriteBuffer()` (I2C).

## Build System

GNU Make based. Key variables in Makefile:

- `ENABLE_*` flags control feature inclusion via `#ifdef` in source
- Compiler: `arm-none-eabi-gcc` with `-mcpu=cortex-m0`
- Optimization: `-Os` (size optimized) with LTO enabled by default
- Output: `firmware.bin` (raw) → `firmware.packed.bin` (encrypted, flashable)

`fw-pack.py` adds the encryption header required by the bootloader.

## Flash Budget Rules

With only 60KB flash and firmware at ~61KB, every byte counts:

- Check size after changes: `arm-none-eabi-size firmware`
- Use `ENABLE_*` flags to disable features when adding new ones
- Prefer lookup tables over computation only when table is smaller
- Avoid `sprintf` where possible (1,088 bytes) — use direct string building
- Font data is 2,952 bytes — consider if new UI elements need new glyphs
- See [ANALYSIS.md](ANALYSIS.md) for per-feature flash costs
