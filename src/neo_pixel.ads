--  SPDX-FileCopyrightText: 2025 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

--  This package allows you to convert pixels from RGB to a bunch of PWM pulses
--  in accordance with the chip specification. The you send this bunch to
--  PWM timer (using DMA probably). To start a new sequence of pixels, pause
--  with a value of zero for the time specified by Reset_Pulse.

package Neo_Pixel is

   type Color is mod 256;
   --  A single color channel value

   type Pixel is record
      Red   : Color;
      Green : Color;
      Blue  : Color;
   end record;
   --  Pixel encoded as RGB

   type Chip_Configuration is record
      Frequency  : Positive;  --  in Hz
      Pulse_One  : Positive;  --  in nano seconds
      Pulse_Zero : Positive;  --  in nano seconds
      Reset      : Positive;  --  in nano seconds
   end record;
   --  Configuration for a particular LED controller chip.

   generic

      type Pulse_Width is mod <>;
      --  Pulse width representation

      type Index is range <>;
      --  An index in pulse width array

      type Pulse_Width_Array is array (Index range <>) of Pulse_Width;
      --  Array of pulse width

      Base_Frequency : Positive;
      --  The frequency that determines the unit of pulse width. For example
      --  1MHz means Pulse_Width in microseconds.

      Chip : Chip_Configuration;
      --  Chip configuration

   package Generic_LED_Strip is

      subtype Pixel_Pulses is Pulse_Width_Array (1 .. 24);
      --  A pixel encoded as 24 pulses, 3 color for 8 pulses each

      function To_Pulses (Pixel : Neo_Pixel.Pixel) return Pixel_Pulses;
      --  Convert a pixel to a bunch of pulses

      function Reset_Pulse return Pulse_Width;
      --  How long reset pulse is

   private

      function Reset_Pulse return Pulse_Width is
        (Pulse_Width (Chip.Reset / (1E9 /  Chip.Frequency)));

   end Generic_LED_Strip;

   SK6812 : constant Chip_Configuration :=
     (Frequency  => 800_000,  --  800 kHz (1.25 us)
      Pulse_Zero => 300,      --  0.3 us
      Pulse_One  => 600,      --  0.6 us
      Reset      => 80_000);  --  80us
   --  Parameters for SK6812 chip

   WS2812 : constant Chip_Configuration :=
     (Frequency  => 800_000,  --  800 kHz (1.25 us)
      Pulse_Zero => 350,      --  0.35 us
      Pulse_One  => 700,      --  0.7 us
      Reset      => 50_000);  --  50us
   --  Parameters for WS2812 chip

   WS2812B : constant Chip_Configuration :=
     (Frequency  => 800_000,  --  800 kHz (1.25 us)
      Pulse_Zero => 400,      --  0.4 us
      Pulse_One  => 800,      --  0.8 us
      Reset      => 50_000);  --  50us
   --  Parameters for WS2812B chip

end Neo_Pixel;
