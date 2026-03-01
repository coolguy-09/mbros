# MBROS
A real OS fitted in just 512 bytes.

## Why use MBROS?
Because it's lightweight and simple.

## How to compile MBROS?
To compile, download some tools.
### On Debian/Ubuntu:
```Bash
sudo apt install nasm make
```
### On Arch:
```Bash
sudo pacman -S nasm make
```

Once you downloaded your tools and source code, run:
```Bash
make
```
## How to use MBROS?
To run MBROS, just run:
```Bash
make run
```

Once the OS boots, you will be greeted by a shell like this:
```
$ _


```
These are the available commands:
```
cls -> Clears the screen.
reboot -> Reboots the system.
halt -> Halts the system.
echo [string] -> Prints a string.
color <hex> -> Changes foreground and background color.
```
