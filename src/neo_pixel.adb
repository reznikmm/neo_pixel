--  SPDX-FileCopyrightText: 2025 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

package body Neo_Pixel is

   -----------------------
   -- Generic_LED_Strip --
   -----------------------

   package body Generic_LED_Strip is

      Duty_0 : constant Pulse_Width :=
        Pulse_Width (Chip.Pulse_Zero / (1E9 / Base_Frequency));

      Duty_1 : constant Pulse_Width :=
        Pulse_Width (Chip.Pulse_One / (1E9 / Base_Frequency));

      ---------------
      -- To_Pulses --
      ---------------

      function To_Pulses (Pixel : Neo_Pixel.Pixel) return Pixel_Pulses is

         procedure Write
           (Color  : Neo_Pixel.Color;
            Result : out Pixel_Pulses;
            Next   : in out Index);

         -----------
         -- Write --
         -----------

         procedure Write
           (Color  : Neo_Pixel.Color;
            Result : out Pixel_Pulses;
            Next   : in out Index)
         is
            Value : Neo_Pixel.Color := Color;
         begin
            for J in 1 .. 8 loop
               Result (Next) :=
                 (if (Value and 16#80#) = 0 then Duty_0 else Duty_1);
               Value := 2 * Value;
               Next := Next + 1;
            end loop;
         end Write;

         Next : Index := 1;
      begin
         return Result : Pixel_Pulses do
            Write (Pixel.Green, Result, Next);
            Write (Pixel.Red, Result, Next);
            Write (Pixel.Blue, Result, Next);
         end return;
      end To_Pulses;

   end Generic_LED_Strip;

end Neo_Pixel;
