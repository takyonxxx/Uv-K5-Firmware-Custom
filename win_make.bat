
@echo off




:: Compile directly in windows without the need of a linux virtual machine:
:: 
:: 1. Download and install "gcc-arm-none-eabi-10.3-2021.10-win32.exe" from https://developer.arm.com/downloads/-/gnu-rm
:: 2. Download and install "gnu_make-3.81.exe" from https://gnuwin32.sourceforge.net/packages/make.htm
::
:: 3. You may (or may not) need to manualy add a path to you OS environment PATH, ie ..
::    C:\Program Files (x86)\GNU Arm Embedded Toolchain\10 2021.10\bin
::
:: 4. You may (or may not) need to reboot windows after installing the above
:: 
:: You can then run this bat from the directory you saved the firmware source code too.



:: You may need to edit/change these three paths to suit your setup
::
:: Temporarily add the compiler, make, and python directories to the system PATH ..
::
@set "PATH=C:\Users\turka\AppData\Local\Programs\Python\Python313;%PATH%"
@set "PATH=C:\Users\turka\AppData\Local\Programs\Python\Python313\Scripts;%PATH%"
@set "PATH=C:\Program Files (x86)\GNU Arm Embedded Toolchain\10 2021.10\bin;%PATH%"
@set "PATH=C:\Program Files (x86)\GNU Arm Embedded Toolchain\10 2021.10\arm-none-eabi\bin;%PATH%"
@set "PATH=C:\Program Files (x86)\GnuWin32\bin;%PATH%"

:: Install crcmod if needed (only needs to run once)
::
python -m pip install --quiet crcmod 2>nul

:: Do the compile
::
make clean
make

:: If Makefile couldn't find python, create packed bin manually
::
if exist firmware.bin (
    if not exist firmware.packed.bin (
        echo.
        echo Creating firmware.packed.bin ...
        python fw-pack.py firmware.bin EGZUMER CUSTOM firmware.packed.bin
    )
)

pause
@echo on
