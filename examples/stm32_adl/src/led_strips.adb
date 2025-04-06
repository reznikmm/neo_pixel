with HAL;
with Interfaces;
with STM32.Device;
with STM32.DMA;
with STM32.GPIO;
with STM32.Timers;
with System.STM32;
with STM32_SVD.DBG;

package body LED_Strips is

   Timer   : STM32.Timers.Timer renames STM32.Device.Timer_3;
   Channel : constant STM32.Timers.Timer_Channel := STM32.Timers.Channel_3;
   DMA     : STM32.DMA.DMA_Controller renames STM32.Device.DMA_1;
   --  Stream  : constant STM32.DMA.DMA_Stream_Selector := STM32.DMA.Stream_7;
   Stream  : constant STM32.DMA.DMA_Stream_Selector := STM32.DMA.Stream_2;

   Dummy : Integer := 0;

   procedure Start_PWM
     (Self   : in out Integer;
      Period : Positive;
      Duty   : Natural;
      Done   : A0B.Callbacks.Callback);
   --  Neo_Pixel adapter for ADL timer driver API

   PWN_Frequency : constant := 12_000_000;  --  83ns

   ---------------
   -- Configure --
   ---------------

   procedure Configure is
      use type System.STM32.Frequency;
   begin
      --  Stop timer in debugger
      STM32_SVD.DBG.DBG_Periph.DBGMCU_APB1_FZ.DBG_TIM3_STOP := True;

      --  Configure pin

      STM32.Device.Enable_Clock (STM32.Device.GPIO_C);

      STM32.GPIO.Configure_IO
        (STM32.Device.PC8,
         Config =>
           (Mode           => STM32.GPIO.Mode_AF,
            Resistors      => STM32.GPIO.Floating,
            AF_Output_Type => STM32.GPIO.Push_Pull,
            AF_Speed       => STM32.GPIO.Speed_Low,
            AF             => STM32.Device.GPIO_AF_TIM3_2));

      --  Configure DMA

      STM32.Device.Enable_Clock (DMA);
      STM32.Device.Reset (DMA);

      STM32.DMA.Configure
        (DMA,
         Stream => Stream,
         Config =>
           (Channel                      => STM32.DMA.Channel_5,
            Direction                    => STM32.DMA.Memory_To_Peripheral,
            Increment_Peripheral_Address => False,
            Increment_Memory_Address     => True,
            Peripheral_Data_Format       => STM32.DMA.HalfWords,
            Memory_Data_Format           => STM32.DMA.HalfWords,
            Operation_Mode               => STM32.DMA.Normal_Mode,
            Priority                     => <>,
            FIFO_Enabled                 => True,
            FIFO_Threshold               => <>,
            Memory_Burst_Size            => <>,
            Peripheral_Burst_Size        => <>));

      --  Configure timer

      STM32.Device.Enable_Clock (Timer);
      STM32.Device.Reset (Timer);
      STM32.Timers.Configure
        (Timer,
         Prescaler     => HAL.UInt16
          (System.STM32.System_Clocks.TIMCLK1 / PWN_Frequency - 1),
         Period        => HAL.UInt32
          (PWN_Frequency / 800_000 - 1),
         Clock_Divisor => STM32.Timers.Div1,
         Counter_Mode  => STM32.Timers.Up);

      STM32.Timers.Configure_Channel_Output
        (Timer,
         Channel  => Channel,
         Mode     => STM32.Timers.PWM1,
         State    => STM32.Timers.Enable,
         Pulse    => 0,
         Polarity => STM32.Timers.High);

      --  STM32.Timers.Set_Autoreload_Preload (Timer, True);
      STM32.Timers.Set_Output_Preload_Enable (Timer, Channel, True);

      STM32.Timers.Configure_DMA
        (Timer,
         Base_Address => STM32.Timers.DMA_Base_CCR3,
         Burst_Length => STM32.Timers.DMA_Burst_Length_1);

      STM32.Timers.Enable_DMA_Source (Timer, STM32.Timers.Timer_DMA_Update);

      STM32.Timers.Enable_Channel (Timer, Channel);

      STM32.Timers.Enable (Timer);
   end Configure;

   ----------------
   -- Next_Pixel --
   ----------------

   procedure Next_Pixel
     (Self  : in out Pixel_Buffer;
      Value : out Neo_Pixel.Pixel)
   is
      use type Neo_Pixel.Color;
   begin
      Value := (16#55#, 16#CC#, 16#EE#);  --  Self.Next;

      Self.Next.Red := Self.Next.Red + 4;
      Self.Next.Green := Self.Next.Green + 4;
      Self.Next.Blue := Self.Next.Blue + 4;
   end Next_Pixel;

   Buffer : array (1 .. 25) of Interfaces.Unsigned_16 := (others => 0);
   Last : Natural := 0;

   ---------------
   -- Start_PWM --
   ---------------

   procedure Start_PWM
     (Self   : in out Integer;
      Period : Positive;
      Duty   : Natural;
      Done   : A0B.Callbacks.Callback)
   is
      pragma Unreferenced (Self, Period);
   begin
      if Duty = 0 then  --  is Reset
         delay 0.000_05;
         A0B.Callbacks.Emit (Done);
         return;
      end if;

      Last := Last + 1;
      Buffer (Last) := Interfaces.Unsigned_16 (Duty);

      if Last < 24 then
         A0B.Callbacks.Emit (Done);
         return;
      end if;

      Last := 0;

      STM32.DMA.Clear_All_Status (DMA, Stream);

      STM32.DMA.Start_Transfer
        (DMA,
         Stream      => Stream,
         Source      => Buffer'Address,
         Destination => System'To_Address (16#4000044C#),  --  DMAR
         Data_Count  => 25);

   --  STM32.Timers.Generate_Event (Timer, STM32.Timers.Event_Source_Update);
   --  STM32.Timers.Generate_Event (Timer, STM32.Timers.Event_Source_Trigger);

      while not STM32.DMA.Status
        (DMA, Stream, STM32.DMA.Transfer_Complete_Indicated)
      loop
         null;
      end loop;

      STM32.Timers.Set_Compare_Value (Timer, Channel, HAL.UInt16'(0));

      A0B.Callbacks.Emit (Done);
   end Start_PWM;

   package LED_Strip is new Neo_Pixel.Generic_LED_Strip
     (PWM_Device    => Integer,
      Start_PWM     => Start_PWM,
      Pixel_Buffer  => Pixel_Buffer,
      Next_Pixel    => Next_Pixel,
      Configuration => Neo_Pixel.WS2812B,
      Device        => Dummy,
      Using         => Dummy_Buffer,
      PWN_Frequency => PWN_Frequency);

   procedure Start_Pixels_Sending
     (Count : Positive;
      Done  : A0B.Callbacks.Callback)
        renames LED_Strip.Start_Pixels_Sending;

end LED_Strips;
