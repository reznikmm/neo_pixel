--  SPDX-FileCopyrightText: 2025 Fil Andrii <root.fi36@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

with STM32.Board;
with STM32.Device;
with STM32.PWM;
with STM32.Timers;
with STM32.DMA;
with HAL;

with Neo_Pixel;

procedure Adl_Stm32 is

   LED_Cnt : constant := 30;

   Controller : STM32.DMA.DMA_Controller renames STM32.Device.DMA_1;

   Configuration : STM32.DMA.DMA_Stream_Configuration;

   Tx_Channel : constant STM32.DMA.DMA_Channel_Selector := STM32.DMA.Channel_6;

   Tx_Stream : constant STM32.DMA.DMA_Stream_Selector := STM32.DMA.Stream_0;

   Selected_Timer : STM32.Timers.Timer renames STM32.Device.Timer_5;

   Timer_AF : constant STM32.GPIO_Alternate_Function :=
     STM32.Device.GPIO_AF_TIM5_2;

   Output_Channel : constant STM32.Timers.Timer_Channel :=
     STM32.Timers.Channel_2;

   Requested_Frequency : constant STM32.PWM.Hertz := 800_000;

   LED_Control : STM32.PWM.PWM_Modulator;

   subtype Pixel_Index is Positive range 1 .. LED_Cnt;

   ---------------
   -- Get_Pixel --
   ---------------

   function Get_Pixel (Time  : Positive; Pixel : Pixel_Index)
     return Neo_Pixel.Pixel
   is

      Red_Speed   : constant := 1300;
      Blue_Speed  : constant := 1900;
      Green_Speed : constant := 3100;

      Red   : constant Positive := Time / Red_Speed mod LED_Cnt + 1;
      Green : constant Positive := Time / Green_Speed mod LED_Cnt + 1;
      Blue  : constant Positive := Time / Blue_Speed mod LED_Cnt + 1;
   begin
      return
        (Red   => (if Red = Pixel then 32 else 0),
         Green => (if Green = Pixel then 32 else 0),
         Blue  => (if Blue = Pixel then 32 else 0));
   end Get_Pixel;

   package WS2812 is new Neo_Pixel.Generic_LED_Strip
     (Pulse_Width       => HAL.UInt32,
      Index             => Natural,
      Pulse_Width_Array => HAL.UInt32_Array,
      Base_Frequency    => 100_000_000,   --  100MHz
      Chip              => Neo_Pixel.WS2812);

   Source_Block : HAL.UInt32_Array (1 .. 2 * 24) := (others => 0);

   Offset : Positive := 1;  --  Half of Buffer pointer: 1 or 24

   Time : Positive := 1;

begin

   STM32.PWM.Configure_PWM_Timer (Selected_Timer'Access, Requested_Frequency);

   LED_Control.Attach_PWM_Channel
     (Selected_Timer'Access,
      Output_Channel,
      STM32.Board.Green_LED,
      Timer_AF);

   LED_Control.Enable_Output;

   STM32.Timers.Set_Output_Preload_Enable
     (Selected_Timer, Output_Channel, True);

   STM32.Timers.Configure_DMA
     (Selected_Timer,
      STM32.Timers.DMA_Base_CCR2,
      STM32.Timers.DMA_Burst_Length_1);

   STM32.Timers.Enable_DMA_Source
     (Selected_Timer, STM32.Timers.Timer_DMA_Update);

   STM32.Device.Enable_Clock (Controller);

   STM32.DMA.Reset (Controller, Tx_Stream);

   Configuration :=
     (Channel                      => Tx_Channel,
      Direction                    => STM32.DMA.Memory_To_Peripheral,
      Increment_Peripheral_Address => False,
      Increment_Memory_Address     => True,
      Peripheral_Data_Format       => STM32.DMA.Words,
      Memory_Data_Format           => STM32.DMA.Words,
      Operation_Mode               => STM32.DMA.Circular_Mode,
      Priority                     => STM32.DMA.Priority_Very_High,
      FIFO_Enabled                 => False,
      others => <>);

   STM32.DMA.Configure (Controller, Tx_Stream, Configuration);

   STM32.DMA.Start_Transfer
     (Controller,
      Tx_Stream,
      Source      => Source_Block'Address,
      Destination => STM32.PWM.Data_Register_Address (LED_Control),
      Data_Count  => Source_Block'Length);

   STM32.Timers.Enable_Capture_Compare_DMA (Selected_Timer);

   loop
      for Pixel in 1 .. LED_Cnt + 3 loop
         --  Wait while half buffer is transmitted
         loop
            if STM32.DMA.Status
              (Controller,
               Tx_Stream,
               STM32.DMA.Half_Transfer_Complete_Indicated)
            then
               STM32.DMA.Clear_Status
                 (Controller,
                  Tx_Stream,
                  STM32.DMA.Half_Transfer_Complete_Indicated);

               exit;
            elsif STM32.DMA.Status
              (Controller,
               Tx_Stream,
               STM32.DMA.Transfer_Complete_Indicated)
            then
               STM32.DMA.Clear_Status
                 (Controller,
                  Tx_Stream,
                  STM32.DMA.Transfer_Complete_Indicated);

               exit;
            end if;
         end loop;

         case Pixel is
            when 1 .. LED_Cnt =>
               Source_Block (Offset .. Offset + 23) := WS2812.To_Pulses
                 (Get_Pixel (Time, Pixel));

            when others =>
               --  Reset
               Source_Block (Offset .. Offset + 23) := (others => 0);
         end case;

         Offset := 26 - Offset;
         Time := Time + 1;
      end loop;
   end loop;
end Adl_Stm32;
