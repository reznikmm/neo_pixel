--  SPDX-FileCopyrightText: 2025 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

with A0B.Callbacks;
--  with Interfaces;

package Neo_Pixel is

   type Color is mod 256;
   --  A single color channel value

   type Pixel is record
      Red   : Color;
      Green : Color;
      Blue  : Color;
   end record;

   type Chip_Configuration is record
      Frequency  : Positive;
      Pulse_One  : Positive;  -- in ns
      Pulse_Zero : Positive;  -- in ns
      Reset      : Positive;  -- in ns
   end record;
   --  Configuration for a particular LED controller chip.

   generic

      type PWM_Device (<>) is limited private;

      with procedure Start_PWM
        (Self   : in out PWM_Device;
         Period : Positive;
         Duty   : Natural;
         Done   : A0B.Callbacks.Callback);
      --  Period and Duty in PWN_Frequency pulses

      type Pixel_Buffer (<>) is limited private;

      with procedure Next_Pixel
        (Self  : in out Pixel_Buffer;
         Value : out Pixel);
      --  This should be fast, because it's called from IRQ, that should
      --  react in 1.25us.

      Configuration : Chip_Configuration;      --  Chip configuration
      Device        : in out PWM_Device;       --  PWM device
      Using         : in out Pixel_Buffer;     --  Pixel source
      PWN_Frequency : Positive := 20_000_000;  --  Timer frequency (50ns)

   package Generic_LED_Strip is

      procedure Start_Pixels_Sending
        (Count : Positive;
         Done  : A0B.Callbacks.Callback);
      --  Start sending Count pixels and return immediately. Callback Done is
      --  called  when all pixels and reset command are sent.

   end Generic_LED_Strip;

   SK6812 : constant Chip_Configuration :=
     (Frequency  => 800_000,  --  800 kHz (1.25 us)
      Pulse_Zero => 300,      --  0.3 us
      Pulse_One  => 600,      --  0.6 us
      Reset      => 80_000);  --  80us

   WS2812 : constant Chip_Configuration :=
     (Frequency  => 800_000,  --  800 kHz (1.25 us)
      Pulse_Zero => 350,      --  0.35 us
      Pulse_One  => 700,      --  0.7 us
      Reset      => 50_000);  --  50us

   WS2812B : constant Chip_Configuration :=
     (Frequency  => 800_000,  --  800 kHz (1.25 us)
      Pulse_Zero => 400,      --  0.4 us
      Pulse_One  => 800,      --  0.8 us
      Reset      => 50_000);  --  50us

end Neo_Pixel;
