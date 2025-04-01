with System;

with Drivers.Timer.TIM_3;

package Devices is

   TIM_3 : Drivers.Timer.TIM_3.Device
     (Priority => System.Interrupt_Priority'First);

end Devices;
