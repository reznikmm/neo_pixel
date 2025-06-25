# Neo_Pixel

[![Build status](https://github.com/reznikmm/neo_pixel/actions/workflows/alire.yml/badge.svg)](https://github.com/reznikmm/neo_pixel/actions/workflows/alire.yml)
[![Alire](https://img.shields.io/endpoint?url=https://alire.ada.dev/badges/neo_pixel.json)](https://alire.ada.dev/crates/neo_pixel.html)
[![REUSE status](https://api.reuse.software/badge/github.com/reznikmm/neo_pixel)](https://api.reuse.software/info/github.com/reznikmm/neo_pixel)

> RGB LED Serial Driver (WS2812, SK6812, etc.)

NeoPixels are individually addressable RGB LEDs that integrate the control
circuit and the RGB chip into a single package. For example,
the WS2812B integrates these components into a 5050 package. They are known
for their simplicity in wiring (single-line data transmission) and their
ability to display 16,777,216 colors (256 brightness levels per primary
color).

This library provides an Ada driver for various serial RGB LEDs, often
referred to as NeoPixels.

## Supported LEDs

This library currently supports the following LED types:

- [**SK6812**](https://www.digikey.com/htmldatasheets/production/1876263/0/0/1/SK6812-Datasheet.pdf)
- [**WS2812**](https://www.digikey.com/htmldatasheets/production/1738016/0/0/1/WS2812-Datasheet.pdf)
- [**WS2812B**](https://www.digikey.com/htmldatasheets/production/1829370/0/0/1/ws2812b.pdf)

## Features

- **Color Conversion**: This library focuses on converting color data for
  individual LEDs into the specific bitstream format required by the
  supported LED types.
- **Microcontroller Agnostic**: The library is designed to be independent
  of any specific microcontroller, operating system, or development board,
  making it highly portable.
- **User-Managed Data Transmission**: This library *does not* handle the
  actual low-level data transmission to the LEDs. This remains the user's
  responsibility. For high-speed data transfer (800kb/s) using DMA
  (Direct Memory Access) is highly recommended for efficient data output
  without tying up the CPU.

## Install

Add `neo_pixel` as a dependency to your crate with Alire:

```bash
alr with neo_pixel
```

## Usage

To use the `Neo_Pixel` library, you first need to define the types
for pulse width, pulse period, and the time interval (base frequency) in
which these values are expressed. You also need to select the specific
LED chip you are using.

For example, let's assume you're using a 32-bit unsigned integer type
(`Interfaces.Unsigned_32`) and the pulse width/period are expressed with
a precision of 0.1 microseconds (which corresponds to a frequency of 10MHz).
In this scenario, you'll also need an array type for `Interfaces.Unsigned_32`
to encode a batch of pulse widths.

Now, you can create an instance of the generic package:

```ada
package WS2812 is new Neo_Pixel.Generic_LED_Strip
  (Pulse_Width       => Interfaces.Unsigned_32,
   Index             => Positive,
   Pulse_Width_Array => Unsigned_32_Array,
   Base_Frequency    => 10_000_000,  -- Your base frequency, 10MHz here
   Chip              => Neo_Pixel.WS2812);
```

Once your system is ready to transmit a batch of data, you use the
`WS2812.To_Pulses` function. This function takes the color of a single
pixel and returns an array of 24 pulse widths (representing 3 color
components, each with 8 pulses). After assembling the desired length
of pulse data for all your LEDs, the user is responsible for transmitting
this pulse array to the hardware device.

```ada
Pixel : Neo_Pixel.Neo_Pixel.Pixel :=
  (Red => 123, Green => 45, Blue => 67);
--  The color of next pixel to control
Batch : Unsigned_32_Array := WS2812.To_Pulses (Pixel);
--  Corresponding 24 pulse width batch encoded in 0.1 us scale
begin
--  Transfer Batch to the led using your DMA and PWM timer configured
--  to 800kHz pulse period.
```

After transmitting the pulse values for all LEDs, a low-level signal
pause (a reset pulse) must be maintained to properly latch the data
in the LEDs. For the WS2812B, this low voltage reset code must be
above 50µs.

## Examples

Two complete example projects are provided to demonstrate the library's
usage on an `STM32F4XX-M` board.
The [first one](examples/aa_stm32/) was built with
[`aa_stm32_drivers`](https://github.com/reznikmm/aa_stm32_drivers).

The [second examlpe](examples/adl_stm32/) uses
[`Ada Drivers Library`](https://github.com/AdaCore/Ada_Drivers_Library).

To build the examples, ensure you have Alire installed and run `alr build`
in the corresponding dirrectory.

### GNAT Studio

Make sure `alr` is in your `PATH` then launch GNAT Studio in the example
directory.

### VS Code

Make sure `alr` is in your `PATH`.

Open the example folder in VS Code. Pre-configured tasks are
available to build projects and flash (using `OpenOCD` or `st-util`).
Install the Cortex Debug extension and `gdb-multiarch`
to launch pre-configured debugger targets.

## Maintainer

[@MaximReznik](https://github.com/reznikmm).

## Contribute

Feel free to dive in!
[Open an issue](https://github.com/reznikmm/neo_pixel/issues/new)
or submit PRs.

## Support

If you find this open source project useful, you may provide me a small support
on [Patreon](https://www.patreon.com/ada_re).

## License

This project is licensed under the Apache 2.0 License with LLVM Exceptions.
See the [LICENSES](LICENSES) files for details.
