with A0B.Callbacks.Generic_Subprogram;
with Ada.Synchronous_Task_Control;

package Suspension_Objec_Callbacks is new A0B.Callbacks.Generic_Subprogram
  (Ada.Synchronous_Task_Control.Suspension_Object,
   Ada.Synchronous_Task_Control.Set_True)
     with Preelaborate;
