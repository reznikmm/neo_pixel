--  SPDX-FileCopyrightText: 2025 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

with A0B.Callbacks.Generic_Subprogram;

with Ada.Synchronous_Task_Control;
with Interfaces;

package body Neo_Pixel is

   package Suspension_Objec_Callbacks is new A0B.Callbacks.Generic_Subprogram
     (Ada.Synchronous_Task_Control.Suspension_Object,
      Ada.Synchronous_Task_Control.Set_True);

   -----------------------
   -- Generic_LED_Strip --
   -----------------------

   package body Generic_LED_Strip is

      procedure Bit_Sent (Again : out Boolean);

      Period : constant Positive :=
         PWN_Frequency / Configuration.Frequency;

      Duty_0 : constant Natural :=
        Configuration.Pulse_Zero / (1E9 / PWN_Frequency);

      Duty_1 : constant Natural :=
        Configuration.Pulse_One / (1E9 / PWN_Frequency);

      Reset : constant Positive :=
        Configuration.Reset / (1E9 / PWN_Frequency);

      Word        : Interfaces.Unsigned_32 := 0;
      Bits_Left   : Natural range 0 .. 24 := 0;
      Pixels_Left : Natural := 0 with Volatile;
      Signal      : A0B.Callbacks.Callback;
      Start_Lock  : Ada.Synchronous_Task_Control.Suspension_Object;
      Send_Lock   : aliased Ada.Synchronous_Task_Control.Suspension_Object;

      Bit_Callback : constant A0B.Callbacks.Callback :=
        Suspension_Objec_Callbacks.Create_Callback (Send_Lock);

      --------------
      -- Bit_Sent --
      --------------

      procedure Bit_Sent (Again : out Boolean) is
         use type Interfaces.Unsigned_32;
         Bit : Boolean;
      begin
         if Bits_Left = 0 then
            if Pixels_Left = 0 then
               --  Send reset (no pulse for 50us) then call Done
               Start_PWM
                 (Device,
                  Period => Reset,
                  Duty   => 0,
                  Done   => Signal);

               Again := False;

               return;

            else

               declare
                  use Interfaces;
                  V : Pixel;
               begin
                  Next_Pixel (Using, V);

                  Word :=
                    Shift_Left (Unsigned_32 (V.Green), 16)
                      + Shift_Left (Unsigned_32 (V.Red), 8)
                      + Unsigned_32 (V.Blue);

                  Pixels_Left := Pixels_Left - 1;
                  Bits_Left := 24;
               end;
            end if;
         end if;

         Bit := (Word and 16#80_00_00#) /= 0;
         Word := Interfaces.Shift_Left (Word, 1);
         Bits_Left := Bits_Left - 1;

         Start_PWM
           (Device,
            Period => Period,
            Duty   => (if Bit then Duty_1 else Duty_0),
            Done   => Bit_Callback);

         Again := True;
      end Bit_Sent;

      --------------------------
      -- Start_Pixels_Sending --
      --------------------------

      procedure Start_Pixels_Sending
        (Count : Positive;
         Done  : A0B.Callbacks.Callback) is
      begin
         Pixels_Left := Count;
         Signal := Done;
         Ada.Synchronous_Task_Control.Set_True (Start_Lock);
      end Start_Pixels_Sending;

      task Sender;

      ------------
      -- Sender --
      ------------

      task body Sender is
         Again : Boolean;
      begin
         loop
            Ada.Synchronous_Task_Control.Suspend_Until_True (Start_Lock);
            Bits_Left := 0;

            loop
               Bit_Sent (Again);
               exit when not Again;
               Ada.Synchronous_Task_Control.Suspend_Until_True (Send_Lock);
            end loop;
         end loop;
      end Sender;

   end Generic_LED_Strip;

end Neo_Pixel;
