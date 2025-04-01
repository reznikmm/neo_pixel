with Ada.Synchronous_Task_Control;
with Suspension_Objec_Callbacks;
with LED_Strips;

procedure Stm32_Demo is

   Pixel_Count : constant := 1;

   Lock : aliased Ada.Synchronous_Task_Control.Suspension_Object;

begin
   LED_Strips.Configure;

   loop
      LED_Strips.Start_Pixels_Sending
        (Pixel_Count,
         Done => Suspension_Objec_Callbacks.Create_Callback (Lock));

      Ada.Synchronous_Task_Control.Suspend_Until_True (Lock);
      --  Wait until pixel sending complete
   end loop;
end Stm32_Demo;
