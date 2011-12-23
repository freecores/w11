-- $Id: sys_conf.vhd 441 2011-12-20 17:01:16Z mueller $
--
-- Copyright 2011- by Walter F.J. Mueller <W.F.J.Mueller@gsi.de>
--
-- This program is free software; you may redistribute and/or modify it under
-- the terms of the GNU General Public License as published by the Free
-- Software Foundation, either version 2, or at your option any later version.
--
-- This program is distributed in the hope that it will be useful, but
-- WITHOUT ANY WARRANTY, without even the implied warranty of MERCHANTABILITY
-- or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
-- for complete details.
--
------------------------------------------------------------------------------
-- Package Name:   sys_conf
-- Description:    Definitions for sys_tst_serloop_s3 (for synthesis)
--
-- Dependencies:   -
-- Tool versions:  xst 13.1; ghdl 0.29
-- Revision History: 
-- Date         Rev Version  Comment
-- 2011-11-13   424   1.0    Initial version
-- 2011-10-25   419   0.5    First draft 
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.slvtypes.all;

package sys_conf is

  constant sys_conf_clkdiv_usecdiv : integer :=   60; -- default usec 
  constant sys_conf_clkdiv_msecdiv : integer := 1000; -- default msec
  constant sys_conf_hio_debounce : boolean := true;   -- instantiate debouncers
  constant sys_conf_uart_cdinit : integer := 521-1;   -- 60000000/115200

end package sys_conf;
