# Quansheng UV-K5/K6 Custom Firmware 

Forked from [egzumer/uv-k5-firmware-custom](https://github.com/egzumer/uv-k5-firmware-custom).

> **Warning:** Use this firmware at your own risk. There is no guarantee it will work on your radio. It may brick your device.

## Changes

### Improved AM Fix

Three improvements to the `am_fix.c` module that reduces AM demodulator saturation/clipping. The original algorithm structure, gain table, and target RSSI (-89dBm) are preserved.

**1. 4-Sample RSSI Sliding Window**

The original code averaged only 2 RSSI samples (old + new), making it susceptible to single-sample spikes causing unnecessary gain changes. The improved code uses a 4-sample sliding window average. The 40ms window provides better spike immunity while still responding fast enough to real signal level changes.

**2. Adaptive Hysteresis**

The original code used a fixed -6dB hysteresis threshold. The improved code adapts based on signal proximity to saturation: -4dB hysteresis when the signal is well above the desired level (fast reaction to prevent distortion), -8dB when near or below (reduces gain hunting on fluctuating signals).

**3. Slower Gain Recovery**

The original code increased gain by one step every 10ms tick. This caused a "pumping" effect where gain would rapidly increase during brief pauses in AM modulation, then immediately drop again when audio returned. The improved code increases gain every 20ms (every other tick), resulting in smoother AM audio without pumping artifacts.

### Spectrum Analyzer: Peak Hold

Added a peak hold trace to the spectrum analyzer display. A dotted line marks the highest signal level observed at each frequency bin since the last scan reset. This makes it easy to spot brief or intermittent transmissions that would otherwise be missed between scan sweeps. The peak hold resets automatically when changing frequency range, scan step, or step count.

Implementation uses a compact `uint8_t` Y-position array (128 bytes RAM) instead of storing full RSSI values, keeping flash usage minimal on the already tight 60KB budget.

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

### Windows

**1. Install required tools**

Open Command Prompt or PowerShell and run:

```
winget install -e -h git.git Python.Python.3.8
winget install -e -h Arm.GnuArmEmbeddedToolchain -v "10 2021.10"
```

Install GNU Make via Chocolatey (run PowerShell as Administrator):

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
choco install make -y
```

**2. Add ARM toolchain to PATH**

The installer may not add the toolchain to PATH automatically. If `arm-none-eabi-gcc --version` is not recognized, add it manually:

```powershell
$env:PATH += ";C:\Program Files (x86)\GNU Arm Embedded Toolchain\10 2021.10\bin"
[Environment]::SetEnvironmentVariable("PATH", $env:PATH, "User")
```

Close and reopen your terminal after this step.

**3. Install Python dependencies**

```
pip install crcmod
```

**4. Clone and build**

```
git clone https://github.com/takyonxxx/uv-k5-firmware-custom.git
cd uv-k5-firmware-custom
win_make.bat
```

The output file is `firmware.packed.bin`.

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

## VS Code Setup (Optional)

The repository includes a `.vscode` folder with pre-configured IntelliSense, build tasks, and recommended extensions for comfortable development:

- **Ctrl+Shift+B** to build firmware
- IntelliSense configured for ARM Cortex-M0 cross-compilation
- Recommended extensions: C/C++, Makefile Tools, ARM Assembly, Cortex-Debug

## Code Analysis

For a detailed breakdown of flash/RAM usage, per-function sizes, feature flag costs, and recommendations on what can be disabled to free up space, see [ANALYSIS.md](ANALYSIS.md).

## License

Apache License 2.0 — see [LICENSE](LICENSE).
