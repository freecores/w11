-- $Id: tb_nexys3_fusp.vhd 444 2011-12-25 10:04:58Z mueller $
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
-- Module Name:    tb_nexys3_fusp - sim
-- Description:    Test bench for nexys3 (base+fusp)
--
-- Dependencies:   simlib/simclk
--                 simlib/simclkcnt
--                 xlib/dcm_sfs
--                 rlink/tb/tbcore_rlink
--                 tb_nexys3_core
--                 serport/serport_uart_rxtx
--                 nexys3_fusp_aif [UUT]
--
-- To test:        generic, any nexys3_fusp_aif target
--
-- Target Devices: generic
-- Tool versions:  xst 13.1; ghdl 0.29
--
-- Revision History: 
-- Date         Rev Version  Comment
-- 2011-12-23   444   1.1    new system clock scheme, new tbcore_rlink iface
-- 2011-11-25   432   1.0    Initial version (derived from tb_nexys2_fusp)
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;

use work.slvtypes.all;
use work.rlinklib.all;
use work.rlinktblib.all;
use work.serport.all;
use work.xlib.all;
use work.nexys3lib.all;
use work.simlib.all;
use work.simbus.all;
use work.sys_conf.all;

entity tb_nexys3_fusp is
end tb_nexys3_fusp;

architecture sim of tb_nexys3_fusp is
  
  signal CLKOSC : slbit := '0';         -- board clock (100 Mhz)
  signal CLKCOM : slbit := '0';         -- communication clock

  signal CLK_STOP : slbit := '0';
  signal CLKCOM_CYCLE : integer := 0;

  signal RESET : slbit := '0';
  signal CLKDIV : slv2 := "00";         -- run with 1 clocks / bit !!
  signal RXDATA : slv8 := (others=>'0');
  signal RXVAL : slbit := '0';
  signal RXERR : slbit := '0';
  signal RXACT : slbit := '0';
  signal TXDATA : slv8 := (others=>'0');
  signal TXENA : slbit := '0';
  signal TXBUSY : slbit := '0';

  signal RX_HOLD : slbit := '0';

  signal I_RXD : slbit := '1';
  signal O_TXD : slbit := '1';
  signal I_SWI : slv8 := (others=>'0');
  signal I_BTN : slv5 := (others=>'0');
  signal O_LED : slv8 := (others=>'0');
  signal O_ANO_N : slv4 := (others=>'0');
  signal O_SEG_N : slv8 := (others=>'0');

  signal O_MEM_CE_N  : slbit := '1';
  signal O_MEM_BE_N  : slv2 := (others=>'1');
  signal O_MEM_WE_N  : slbit := '1';
  signal O_MEM_OE_N  : slbit := '1';
  signal O_MEM_ADV_N : slbit := '1';
  signal O_MEM_CLK   : slbit := '0';
  signal O_MEM_CRE   : slbit := '0';
  signal I_MEM_WAIT  : slbit := '0';
  signal O_MEM_ADDR  : slv23 := (others=>'Z');
  signal IO_MEM_DATA : slv16 := (others=>'0');
  signal O_PPCM_CE_N   : slbit := '0';
  signal O_PPCM_RST_N  : slbit := '0';

  signal O_FUSP_RTS_N : slbit := '0';
  signal I_FUSP_CTS_N : slbit := '0';
  signal I_FUSP_RXD : slbit := '1';
  signal O_FUSP_TXD : slbit := '1';

  signal UART_RESET : slbit := '0';
  signal UART_RXD : slbit := '1';
  signal UART_TXD : slbit := '1';
  signal CTS_N : slbit := '0';
  signal RTS_N : slbit := '0';

  signal R_PORTSEL : slbit := '0';

  constant sbaddr_portsel: slv8 := slv(to_unsigned( 8,8));

  constant clock_period : time :=  10 ns;
  constant clock_offset : time := 200 ns;

begin
  
  CLKGEN : simclk
    generic map (
      PERIOD => clock_period,
      OFFSET => clock_offset)
    port map (
      CLK      => CLKOSC,
      CLK_STOP => CLK_STOP
    );
  
  DCM_COM : dcm_sfs
    generic map (
      CLKFX_DIVIDE   => sys_conf_clkfx_divide,
      CLKFX_MULTIPLY => sys_conf_clkfx_multiply,
      CLKIN_PERIOD   => 10.0)
    port map (
      CLKIN   => CLKOSC,
      CLKFX   => CLKCOM,
      LOCKED  => open
    );

  CLKCNT : simclkcnt port map (CLK => CLKCOM, CLK_CYCLE => CLKCOM_CYCLE);

  TBCORE : tbcore_rlink
    port map (
      CLK      => CLKCOM,
      CLK_STOP => CLK_STOP,
      RX_DATA  => TXDATA,
      RX_VAL   => TXENA,
      RX_HOLD  => RX_HOLD,
      TX_DATA  => RXDATA,
      TX_ENA   => RXVAL
    );

  RX_HOLD <= TXBUSY or RTS_N;           -- back preasure for data flow to tb

  N3CORE : entity work.tb_nexys3_core
    port map (
      I_SWI       => I_SWI,
      I_BTN       => I_BTN,
      O_MEM_CE_N  => O_MEM_CE_N,
      O_MEM_BE_N  => O_MEM_BE_N,
      O_MEM_WE_N  => O_MEM_WE_N,
      O_MEM_OE_N  => O_MEM_OE_N,
      O_MEM_ADV_N => O_MEM_ADV_N,
      O_MEM_CLK   => O_MEM_CLK,
      O_MEM_CRE   => O_MEM_CRE,
      I_MEM_WAIT  => I_MEM_WAIT,
      O_MEM_ADDR  => O_MEM_ADDR,
      IO_MEM_DATA => IO_MEM_DATA
    );

  UUT : nexys3_fusp_aif
    port map (
      I_CLK100     => CLKOSC,
      I_RXD        => I_RXD,
      O_TXD        => O_TXD,
      I_SWI        => I_SWI,
      I_BTN        => I_BTN,
      O_LED        => O_LED,
      O_ANO_N      => O_ANO_N,
      O_SEG_N      => O_SEG_N,
      O_MEM_CE_N   => O_MEM_CE_N,
      O_MEM_BE_N   => O_MEM_BE_N,
      O_MEM_WE_N   => O_MEM_WE_N,
      O_MEM_OE_N   => O_MEM_OE_N,
      O_MEM_ADV_N  => O_MEM_ADV_N,
      O_MEM_CLK    => O_MEM_CLK,
      O_MEM_CRE    => O_MEM_CRE,
      I_MEM_WAIT   => I_MEM_WAIT,
      O_MEM_ADDR   => O_MEM_ADDR,
      IO_MEM_DATA  => IO_MEM_DATA,
      O_PPCM_CE_N  => O_PPCM_CE_N,
      O_PPCM_RST_N => O_PPCM_RST_N,
      O_FUSP_RTS_N => O_FUSP_RTS_N,
      I_FUSP_CTS_N => I_FUSP_CTS_N,
      I_FUSP_RXD   => I_FUSP_RXD,
      O_FUSP_TXD   => O_FUSP_TXD
    );

  UART : serport_uart_rxtx
    generic map (
      CDWIDTH => CLKDIV'length)
    port map (
      CLK    => CLKCOM,
      RESET  => UART_RESET,
      CLKDIV => CLKDIV,
      RXSD   => UART_RXD,
      RXDATA => RXDATA,
      RXVAL  => RXVAL,
      RXERR  => RXERR,
      RXACT  => RXACT,
      TXSD   => UART_TXD,
      TXDATA => TXDATA,
      TXENA  => TXENA,
      TXBUSY => TXBUSY
    );

  proc_port_mux: process (R_PORTSEL, UART_TXD, CTS_N,
                          O_TXD, O_FUSP_TXD, O_FUSP_RTS_N)
  begin

    if R_PORTSEL = '0' then             -- use main board rs232, no flow cntl
      I_RXD        <= UART_TXD;           -- write port 0 inputs
      UART_RXD     <= O_TXD;              -- get port 0 outputs
      RTS_N        <= '0';
      I_FUSP_RXD   <= '1';                -- port 1 inputs to idle state
      I_FUSP_CTS_N <= '0';
    else                                -- otherwise use pmod1 rs232
      I_FUSP_RXD   <= UART_TXD;           -- write port 1 inputs
      I_FUSP_CTS_N <= CTS_N;
      UART_RXD     <= O_FUSP_TXD;         -- get port 1 outputs
      RTS_N        <= O_FUSP_RTS_N;
      I_RXD        <= '1';                -- port 0 inputs to idle state
    end if;
    
  end process proc_port_mux;

  proc_moni: process
    variable oline : line;
  begin
    
    loop
      wait until rising_edge(CLKCOM);

      if RXERR = '1' then
        writetimestamp(oline, CLKCOM_CYCLE, " : seen RXERR=1");
        writeline(output, oline);
      end if;
      
    end loop;
    
  end process proc_moni;

  proc_simbus: process (SB_VAL)
  begin
    if SB_VAL'event and to_x01(SB_VAL)='1' then
      if SB_ADDR = sbaddr_portsel then
        R_PORTSEL <= to_x01(SB_DATA(0));
      end if;
    end if;
  end process proc_simbus;

end sim;
