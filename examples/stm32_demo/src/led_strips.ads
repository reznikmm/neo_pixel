with Neo_Pixel;
with Drivers.Timer.TIM_3;
with A0B.Callbacks;

package LED_Strips is

   procedure Configure;
   --  Initialize hardware

   procedure Start_Pixels_Sending
     (Count : Positive;
      Done  : A0B.Callbacks.Callback);
   --  Start sending Count pixels and return immediately. Callback Done is
   --  called  when all pixels and reset command are sent.

private

   type Pixel_Buffer is record
      Next : Neo_Pixel.Pixel := (128, 16, 0);
   end record;
   --  A dummy pixel source

   procedure Next_Pixel
     (Self  : in out Pixel_Buffer;
      Value : out Neo_Pixel.Pixel);
   --  Provide next pixel to send

   Dummy_Buffer : Pixel_Buffer;

   procedure Start_PWM
     (Self   : in out Drivers.Timer.TIM_3.Device;
      Period : Positive;
      Duty   : Natural;
      Done   : A0B.Callbacks.Callback)
        with Inline;
   --  Neo_Pixel adapter for timer driver API

   PWN_Frequency : constant := 20_000_000;  --  50ns

end LED_Strips;
