# Quansheng UV-K5/K6 Custom Firmware (Maren Edition)

Forked from [egzumer/uv-k5-firmware-custom](https://github.com/egzumer/uv-k5-firmware-custom), which is a merge of [OneOfEleven custom firmware](https://github.com/OneOfEleven/uv-k5-firmware-custom) with [fagci spectrum analyzer](https://github.com/fagci/uv-k5-firmware-fagci-mod/tree/refactor). All based on [DualTachyon's open firmware](https://github.com/DualTachyon/uv-k5-firmware).

> **Warning:** Use this firmware at your own risk (entirely). There is absolutely no guarantee that it will work in any way shape or form on your radio(s), it may even brick your radio(s), in which case, you'd need to buy another radio. Anyway, have fun.

## Maren Custom Changes

### Simplified Menu System

The menu has been reorganized into visible and hidden sections. Frequently used items are immediately accessible, rarely used items are moved to the hidden menu (accessible by holding PTT + upper side button during power-on).

**Visible menu (13 items):** Sql, Step, TxPwr, W/N, Demod, Mic, AM Fix, VOX, BatVol, BackLt, Beep, RxMode, VER

**Hidden menu (moved from visible):** RxDCS, RxCTCS, TxDCS, TxCTCS, TxODir, TxOffs, BusyCL, Compnd, ChSave, ChDele, ChName, Scramb, ScAdd1/2, SList/1/2, ScnRev, F1Shrt/Long, F2Shrt/Long, M Long, KeyLck, TxTOut, BatSav, MicBar, ChDisp, POnMsg, BatTxt, BLMin/Max, BltTRX, Roger, STE, RP STE, 1 Call, all DTMF items, plus the original hidden items (F Lock, Tx 200/350/500, 350 En, ScraEn, FrCali, BatCal, BatTyp, Reset).

### Automatic AM Demodulation for Airband

Frequencies in the 118-136 MHz aviation band automatically switch to AM demodulation. This works in three places: when entering a frequency via keypad, when tuning with UP/DOWN in VFO mode, and when loading channels from EEPROM. Leaving the airband automatically returns to FM.

### TX on All Frequencies

The `TX_freq_check` function has been modified to allow transmission on all valid frequencies (BX4819 chip gap excluded). The `ENABLE_TX_WHEN_AM` flag is enabled, allowing TX in AM mode. Note that BK4819 hardware only supports FM modulation for TX regardless of the demod setting.

### Spectrum Analyzer

The original fagci spectrum analyzer is retained with peak hold functionality. Access via the assigned side button.

### Recommended Airband Frequencies (Ankara)

For testing AM reception on the aviation band (118-136 MHz, auto-AM enabled):
- 118.100 — Esenboğa TWR (Tower)
- 119.100 — Esenboğa Approach
- 121.500 — International emergency frequency
- 121.800 — Esenboğa Ground
- 124.000 — Ankara ATIS (continuous automated broadcast, best for testing)
- 127.800 — Ankara ACC (Area Control)

### Version String Fix

The version string in the menu has been split across two lines so it fits the 128px wide display without truncation.

### Demodulation Menu Renamed

The demodulation type menu item has been renamed from "Demodu" to "Demod" for clarity.

## Improved AM Fix (from upstream)

Three improvements to the `am_fix.c` module that reduces AM demodulator saturation/clipping. The original algorithm structure, gain table, and target RSSI (-89dBm) are preserved: 4-sample RSSI sliding window, adaptive hysteresis, and slower gain recovery to prevent pumping artifacts.

## Flashing the Firmware

1. Open [https://whosmatt.github.io/uvmod/](https://whosmatt.github.io/uvmod/) in Chrome or Edge.
2. Turn off the radio.
3. Press and hold the PTT button, then turn on the radio while still holding PTT. The flashlight should turn on while the screen stays dark — the radio is now in bootloader mode.
4. Connect the programming cable (Baofeng/Kenwood type USB serial cable) to the radio.
5. Click **"Flash directly"** on the UVMOD page.
6. Select the `firmware.packed.bin` file from the build output.
7. Select the COM port and click **Connect**.
8. Wait for the process to finish. Your settings should remain intact.

## Building from Source

### Windows (Recommended)

**1. Install ARM Toolchain**

Download and install `gcc-arm-none-eabi-10.3-2021.10-win32.exe` from [ARM Developer](https://developer.arm.com/downloads/-/gnu-rm). Default install path: `C:\Program Files (x86)\GNU Arm Embedded Toolchain\10 2021.10\`

**2. Install GNU Make**

Download and install `gnu_make-3.81.exe` from [GnuWin32](https://gnuwin32.sourceforge.net/packages/make.htm). Default install path: `C:\Program Files (x86)\GnuWin32\`

**3. Install Python 3**

Download from [python.org](https://www.python.org/downloads/). During installation, check **"Add python.exe to PATH"**. After install:

```
python -m pip install crcmod
```

**4. Build**

Edit `win_make.bat` and verify the three PATH lines match your install locations:

```bat
@set "PATH=C:\Users\YOUR_USER\AppData\Local\Programs\Python\Python3XX;%PATH%"
@set "PATH=C:\Users\YOUR_USER\AppData\Local\Programs\Python\Python3XX\Scripts;%PATH%"
@set "PATH=C:\Program Files (x86)\GNU Arm Embedded Toolchain\10 2021.10\bin;%PATH%"
@set "PATH=C:\Program Files (x86)\GNU Arm Embedded Toolchain\10 2021.10\arm-none-eabi\bin;%PATH%"
@set "PATH=C:\Program Files (x86)\GnuWin32\bin;%PATH%"
```

Then run:

```
win_make.bat
```

Output files: `firmware.bin` and `firmware.packed.bin`

**Common issues:**
- `'make' is not recognized` — GnuWin32 not installed or not in PATH
- `'arm-none-eabi-gcc' not found` — ARM toolchain not installed or PATH mismatch in `win_make.bat`
- `'python' not recognized` — Python not in PATH. Find your Python install location and update the PATH in `win_make.bat`
- `PYTHON NOT FOUND, *.PACKED.BIN WON'T BE BUILT` — Python PATH not set before `make` runs. Ensure Python PATH lines are at the top of `win_make.bat`

### Linux (Ubuntu/Debian)

```bash
sudo apt update
sudo apt install -y git make python3 python3-pip gcc-arm-none-eabi
pip3 install crcmod

git clone https://github.com/takyonxxx/uv-k5-firmware-custom.git
cd uv-k5-firmware-custom
make
```

### Linux (Arch/Manjaro)

```bash
sudo pacman -S git make python python-pip arm-none-eabi-gcc arm-none-eabi-newlib
pip install crcmod

git clone https://github.com/takyonxxx/uv-k5-firmware-custom.git
cd uv-k5-firmware-custom
make
```

### macOS

```bash
brew install git python3 armmbed/formulae/arm-none-eabi-gcc
pip3 install crcmod

git clone https://github.com/takyonxxx/uv-k5-firmware-custom.git
cd uv-k5-firmware-custom
make
```

### Docker (any platform)

```bash
git clone https://github.com/takyonxxx/uv-k5-firmware-custom.git
cd uv-k5-firmware-custom
./compile-with-docker.sh
```

On Windows use `compile-with-docker.bat` instead.

## Modified Files Summary

| File | Changes |
|------|---------|
| `win_make.bat` | Fixed PATH quoting, added Python path |
| `ui/menu.c` | Menu reorganization (visible/hidden), renamed Demod |
| `version.c` | Version string split to two lines |
| `radio.c` | Auto AM for airband 118-136 MHz on channel load |
| `app/main.c` | Auto AM for airband on keypad entry and VFO tuning |
| `app/spectrum.c` | Original (unchanged) |
| `frequencies.c` | TX allowed on all frequencies |
| `Makefile` | `ENABLE_TX_WHEN_AM = 1` |

## Code Analysis

For a detailed breakdown of flash/RAM usage, per-function sizes, feature flag costs, and recommendations on what can be disabled to free up space, see [ANALYSIS.md](ANALYSIS.md).

For a developer-oriented overview of the code architecture, source tree, execution flow, and key subsystems, see [DEVELOPER.md](DEVELOPER.md).

## Credits

This firmware is built upon the work of:

- [DualTachyon](https://github.com/DualTachyon) — original open firmware reverse engineering
- [OneOfEleven](https://github.com/OneOfEleven) — AM fix, fast scanning, and many improvements
- [fagci](https://github.com/fagci) — spectrum analyzer
- [egzumer](https://github.com/egzumer) — merged firmware with additional features
- [Maren](https://github.com/takyonxxx) — menu simplification, airband auto-AM, spectrum rewrite, TX unlock

## License

Apache License 2.0 — see [LICENSE](LICENSE).
