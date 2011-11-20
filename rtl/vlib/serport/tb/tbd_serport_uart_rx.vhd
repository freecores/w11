-- $Id: tbd_serport_uart_rx.vhd 417 2011-10-22 10:30:29Z mueller $
--
-- Copyright 2007-2011 by Walter F.J. Mueller <W.F.J.Mueller@gsi.de>
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
-- Module Name:    tbd_serport_uart_rx - syn
-- Description:    Wrapper for serport_uart_rx to avoid records. It
--                 has a port interface which will not be modified by xst
--                 synthesis (no records, no generic port).
--
-- Dependencies:   serport_uart_rx
--
-- To test:        serport_uart_rx
--
-- Target Devices: generic
--
-- Synthesized (xst):
-- Date         Rev  ise         Target      flop lutl lutm slic t peri
-- 2007-10-27    92  9.2.02 J39  xc3s1000-4    26   67    0    - t 8.17
-- 2007-10-27    92  9.1    J30  xc3s1000-4    26   67    0    - t 8.25
-- 2007-10-27    92  8.2.03 I34  xc3s1000-4    29   90    0   47 s 8.45
-- 2007-10-27    92  8.1.03 I27  xc3s1000-4    31   92    0    - s 8.25
--
-- Tool versions:  xst 8.2, 9.1, 9.2, 13.1; ghdl 0.18-0.29
-- Revision History: 
-- Date         Rev Version  Comment
-- 2007-10-21    91   1.0    Initial version 
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.slvtypes.all;
use work.serport.all;

entity tbd_serport_uart_rx is           -- serial port uart rx [tb design]
                                        -- generic: CDWIDTH=5
  port (
    CLK : in slbit;                     -- clock
    RESET : in slbit;                   -- reset
    CLKDIV : in slv5;                   -- clock divider setting
    RXSD : in slbit;                    -- receive serial data (uart view)
    RXDATA : out slv8;                  -- receiver data out
    RXVAL : out slbit;                  -- receiver data valid
    RXERR : out slbit;                  -- receiver data error (frame error)
    RXACT : out slbit                   -- receiver active
  );
end tbd_serport_uart_rx;


architecture syn of tbd_serport_uart_rx is

begin

  UART : serport_uart_rx
    generic map (
      CDWIDTH => 5)
    port map (
      CLK    => CLK,
      RESET  => RESET,
      CLKDIV => CLKDIV,
      RXSD   => RXSD,
      RXDATA => RXDATA,
      RXVAL  => RXVAL,
      RXERR  => RXERR,
      RXACT  => RXACT
    );
  
end syn;
