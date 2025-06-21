--  SPDX-FileCopyrightText: 2025 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

with Ada.Synchronous_Task_Control;

with A0B.Callbacks.Generic_Subprogram;

package Unlocks is new A0B.Callbacks.Generic_Subprogram
  (Object_Type => Ada.Synchronous_Task_Control.Suspension_Object,
   Subprogram  => Ada.Synchronous_Task_Control.Set_True);
