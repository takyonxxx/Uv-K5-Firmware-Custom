# Firmware Code Analysis — Quansheng UV-K5/K6 Custom Fork

## Flash Budget

| Item | Size |
|---|---|
| Flash limit | 61,440 bytes (60KB) |
| Current firmware (text) | 61,376 bytes |
| Remaining | **64 bytes** |
| RAM limit | 16,384 bytes (16KB) |
| RAM used (bss) | 3,300 bytes |
| RAM remaining | ~13,084 bytes |

**Flash is critical. RAM is comfortable.**

## Top 20 Largest Functions

| Size (bytes) | Function | Module |
|---|---|---|
| 8,368 | Main | main.c |
| 3,320 | APP_RunSpectrum | app/spectrum.c |
| 2,476 | UI_DisplayMenu | ui/menu.c |
| 2,128 | UI_DisplayMain | ui/main.c |
| 1,596 | MENU_AcceptSetting | app/menu.c |
| 1,452 | ProcessKey | app/app.c |
| 1,316 | gFontBig (data) | font.c |
| 1,268 | MENU_ProcessKeys | app/menu.c |
| 1,208 | MAIN_ProcessKeys | app/main.c |
| 1,088 | sprintf_ | external/printf |
| 1,040 | FUNCTION_Select | functions.c |
| 948 | MENU_ShowCurrentSetting | app/menu.c |
| 914 | RADIO_ConfigureChannel | radio.c |
| 752 | DTMF_HandleRequest | app/dtmf.c |
| 732 | SCANNER_ProcessKeys | app/scanner.c |
| 712 | FM_ProcessKeys | app/fm.c |
| 660 | SETTINGS_SaveSettings | settings.c |
| 648 | UI_DisplayStatus | ui/status.c |
| 630 | MenuList (data) | app/menu.c |
| 596 | RADIO_SetupRegisters | radio.c |

## Font Data in Flash

| Font | Size (bytes) |
|---|---|
| gFontBig | 1,316 |
| gFontSmall | 564 |
| gFontSmallBold | 564 |
| gFont3x5 | 288 |
| gFontBigDigits | 220 |
| **Total fonts** | **2,952** |

## Feature Flag Flash Cost

Measured by disabling each feature individually and comparing text size:

| Savings | Feature Flag | What It Does | Recommendation |
|---|---|---|---|
| 5,824 | ENABLE_SPECTRUM | Built-in spectrum analyzer. Shows RF activity across a frequency range as a waterfall-style bar graph. Supports peak hold, modulation switching, squelch trigger, and frequency input. | **KEEP** — core feature |
| 3,872 | ENABLE_FMRADIO | FM broadcast radio receiver (76-108 MHz). Allows listening to commercial FM radio stations with channel memory and auto-scan. Completely separate from VHF/UHF ham operation. | **CAN REMOVE** — not needed for ham/airband/marine use |
| 2,532 | ENABLE_DTMF_CALLING | DTMF "phone call" system: contact list, group calls, auto-answer, call notifications. Does NOT affect basic DTMF tone sending — repeater access (`*`, `#`, A-D tones) still works without this. | **CAN REMOVE** — rarely used, basic DTMF tones unaffected |
| 1,544 | ENABLE_UART | Serial UART communication for PC configuration tools (CHIRP, CPS software), firmware commands, and EEPROM read/write over programming cable. | **KEEP** — needed for PC configuration |
| 608 | ENABLE_SMALL_BOLD | Adds a bold variant of the small font (564 bytes of font data). Used for emphasis in menus and status display. Without it, all small text renders in regular weight. | **CAN REMOVE** — barely noticeable visual difference |
| 572 | ENABLE_VOX | Voice-Operated Transmit. Automatically keys the transmitter when you speak into the microphone, hands-free operation. Requires threshold calibration per environment. | **CAN REMOVE** — most users prefer PTT button |
| 444 | ENABLE_AM_FIX | Software AGC for AM reception. Dynamically adjusts RF front-end gain to prevent BK4819 AM demodulator saturation on strong signals. Our fork includes improved 4-sample averaging, adaptive hysteresis, and anti-pumping. | **KEEP** — our core improvement |
| 320 | ENABLE_AUDIO_BAR | Shows a real-time audio level bar on screen during TX. Visual feedback for microphone input level. Cosmetic only, does not affect audio processing. | **CAN REMOVE** — cosmetic, no functional impact |
| 316 | ENABLE_RSSI_BAR | Shows a signal strength (RSSI) bar on the main screen during RX. Visual indication of received signal level alongside the S-meter value. | **KEEP** — useful operational feedback |
| 268 | ENABLE_SCAN_RANGES | Enables custom scan ranges in the spectrum analyzer. Allows defining start/stop frequencies for targeted spectrum sweeps instead of fixed bandwidth around center frequency. | **KEEP** — extends spectrum analyzer usefulness |
| 184 | ENABLE_FLASHLIGHT | Toggles the radio's LED flashlight via side button. Three modes: on, blink, SOS. | **CAN REMOVE** — minor utility feature |
| 168 | ENABLE_BIG_FREQ | Displays the frequency in a large font on the main screen. Without it, frequency uses the standard smaller font. | **CAN REMOVE** — cosmetic preference |

## Removal Priority (most flash saved, least functionality lost)

### Tier 1 — Safe to remove (6,404 bytes total)

| Action | Savings | Impact |
|---|---|---|
| ENABLE_FMRADIO=0 | 3,872 | Lose FM broadcast radio. Not related to ham/airband use. |
| ENABLE_DTMF_CALLING=0 | 2,532 | Lose DTMF contact calling and groups. Basic DTMF tones still work for repeater access. |

### Tier 2 — Cosmetic removals (1,280 bytes total)

| Action | Savings | Impact |
|---|---|---|
| ENABLE_SMALL_BOLD=0 | 608 | All small text uses regular font instead of bold. Barely noticeable. |
| ENABLE_VOX=0 | 572 | Lose voice-activated TX. Usable if you always use PTT button. |
| ENABLE_AUDIO_BAR=0 | 320 | Lose TX audio level indicator bar. |

### Tier 3 — Minor removals (352 bytes total)

| Action | Savings | Impact |
|---|---|---|
| ENABLE_FLASHLIGHT=0 | 184 | Lose flashlight toggle. |
| ENABLE_BIG_FREQ=0 | 168 | Frequency display uses smaller font. |

## How to Apply

Edit the top of `Makefile` and set the desired flags to `0`:

```makefile
ENABLE_FMRADIO                ?= 0
ENABLE_DTMF_CALLING           ?= 0
```

Then rebuild:
```
win_make.bat
```

## Summary

| Scenario | Flash freed | Remaining |
|---|---|---|
| Current firmware | 0 | 64 bytes |
| Tier 1 only (FM + DTMF) | 6,404 | 6,468 bytes |
| Tier 1 + Tier 2 | 7,684 | 7,748 bytes |
| All tiers | 8,036 | 8,100 bytes |

Removing FM Radio and DTMF Calling alone frees 6.4KB — enough room for significant new features while losing functionality that most UV-K5/K6 users in the ham/airband/marine community don't actively use.
