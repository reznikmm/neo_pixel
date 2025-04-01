with Devices;
with Interfaces;

package body LED_Strips is

   ---------------
   -- Configure --
   ---------------

   procedure Configure is
      --  use type Interfaces.Unsigned_32;
   begin
      Drivers.Timer.TIM_3.Configure
        (Devices.TIM_3,
         Pin   => ('C', 8),
         Speed => LED_Strips.PWN_Frequency);
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
      Value := (0, 0, 0);  --  Self.Next;

      Self.Next.Red := Self.Next.Red + 4;
      Self.Next.Green := Self.Next.Green + 4;
      Self.Next.Blue := Self.Next.Blue + 4;
   end Next_Pixel;

   ---------------
   -- Start_PWM --
   ---------------

   procedure Start_PWM
     (Self   : in out Drivers.Timer.TIM_3.Device;
      Period : Positive;
      Duty   : Natural;
      Done   : A0B.Callbacks.Callback) is
   begin
      Drivers.Timer.TIM_3.Start_PWM
        (Self,
         Period => Interfaces.Unsigned_16 (Period),
         Duty   => Interfaces.Unsigned_16 (Duty),
         Done   => Done);
   end Start_PWM;

   package LED_Strip is new Neo_Pixel.Generic_LED_Strip
     (PWM_Device    => Drivers.Timer.TIM_3.Device,
      Start_PWM     => Start_PWM,
      Pixel_Buffer  => Pixel_Buffer,
      Next_Pixel    => Next_Pixel,
      Configuration => Neo_Pixel.WS2812B,
      Device        => Devices.TIM_3,
      Using         => Dummy_Buffer,
      PWN_Frequency => PWN_Frequency);

   procedure Start_Pixels_Sending
     (Count : Positive;
      Done  : A0B.Callbacks.Callback)
        renames LED_Strip.Start_Pixels_Sending;

end LED_Strips;
