--  SPDX-FileCopyrightText: 2025 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

with Ada.Synchronous_Task_Control;
with Neo_Pixel;
with Devices;
with STM32.Timer;
with Interfaces;
with Unlocks;

procedure Aa_Stm32 is
   package TIM renames Devices.TIM_5;

   PWM_Base_Freq : constant := 21_000_000;

   Pixels : constant := 12;

   subtype Pixel_Index is Positive range 1 .. Pixels;

   package WS2812 is new Neo_Pixel.Generic_LED_Strip
     (Pulse_Width       => Interfaces.Unsigned_32,
      Index             => Positive,
      Pulse_Width_Array => STM32.Timer.Unsigned_32_Array,
      Base_Frequency    => PWM_Base_Freq,
      Chip              => Neo_Pixel.WS2812);

   ---------------
   -- Get_Pixel --
   ---------------

   function Get_Pixel (Time  : Positive; Pixel : Pixel_Index)
     return Neo_Pixel.Pixel
   is

      Red_Speed   : constant := 1300;
      Blue_Speed  : constant := 1900;
      Green_Speed : constant := 3100;

      Red   : constant Positive := Time / Red_Speed mod Pixels + 1;
      Green : constant Positive := Time / Green_Speed mod Pixels + 1;
      Blue  : constant Positive := Time / Blue_Speed mod Pixels + 1;
   begin
      return
        (Red   => (if Red = Pixel then 32 else 0),
         Green => (if Green = Pixel then 32 else 0),
         Blue  => (if Blue = Pixel then 32 else 0));
   end Get_Pixel;

   Lock   : aliased Ada.Synchronous_Task_Control.Suspension_Object;
   Buffer : STM32.Timer.Unsigned_32_Array (1 .. 48) := (others => 0);  --  2x24
   Offset : Positive := 1;  --  Half of Buffer pointer: 1 or 24
   Time   : Positive := 1;
begin
   TIM.Configure_PWM
     (Pins   => (2 => (STM32.PA, 1)),  --  Make only Channel 2 active
      Speed  => PWM_Base_Freq,
      Period =>
        Interfaces.Unsigned_32 (PWM_Base_Freq / Neo_Pixel.WS2812.Frequency),
      Duty   => 0);

   TIM.Start_PWM_With_Duty
     (Buffer, On_Half => Unlocks.Create_Callback (Lock));

   loop
      for Pixel in 1 .. Pixels + 3 loop  --  Use 3 last pixels for Reset
         Ada.Synchronous_Task_Control.Suspend_Until_True (Lock);

         case Pixel is
            when 1 .. Pixels =>
               Buffer (Offset .. Offset + 23) := WS2812.To_Pulses
                 (Get_Pixel (Time, Pixel));

            when others =>
               --  Reset
               Buffer (Offset .. Offset + 23) := (others => 0);
         end case;

         Offset := 26 - Offset;
         Time := Time + 1;
      end loop;
   end loop;
end Aa_Stm32;
