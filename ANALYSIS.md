# Firmware Code Analysis — Quansheng UV-K5/K6 Maren Fork

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

| Savings (bytes) | Feature Flag | Description | Recommendation |
|---|---|---|---|
| 5,824 | ENABLE_SPECTRUM | Spectrum analyzer | **KEEP** — core feature |
| 3,872 | ENABLE_FMRADIO | FM broadcast radio receiver | **CAN REMOVE** — saves most flash |
| 2,532 | ENABLE_DTMF_CALLING | DTMF calling/contacts/groups | **CAN REMOVE** — rarely used in field |
| 1,544 | ENABLE_UART | Serial UART communication | **KEEP** — needed for configuration |
| 608 | ENABLE_SMALL_BOLD | Bold variant of small font | **CAN REMOVE** — 564 bytes font data |
| 572 | ENABLE_VOX | Voice-activated transmit | **CAN REMOVE** — rarely needed |
| 444 | ENABLE_AM_FIX | AM demodulator fix | **KEEP** — our improvement |
| 320 | ENABLE_AUDIO_BAR | TX audio level bar | **CAN REMOVE** — cosmetic |
| 316 | ENABLE_RSSI_BAR | RX signal strength bar | **KEEP** — useful visual feedback |
| 268 | ENABLE_SCAN_RANGES | Scan range support in spectrum | **KEEP** — useful with spectrum |
| 184 | ENABLE_FLASHLIGHT | Flashlight function | **CAN REMOVE** — minor utility |
| 168 | ENABLE_BIG_FREQ | Large frequency display | **CAN REMOVE** — cosmetic |

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
