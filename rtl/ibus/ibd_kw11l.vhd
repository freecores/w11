-- $Id: ibd_kw11l.vhd 314 2010-07-09 17:38:41Z mueller $
--
-- Copyright 2008-2009 by Walter F.J. Mueller <W.F.J.Mueller@gsi.de>
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
-- Module Name:    ibd_kw11l - syn
-- Description:    ibus dev(loc): KW11-L (line clock)
--
-- Dependencies:   -
-- Test bench:     -
-- Target Devices: generic
-- Tool versions:  xst 8.1, 8.2, 9.1, 9.2, 10.1; ghdl 0.18-0.25
--
-- Synthesized (xst):
-- Date         Rev  ise         Target      flop lutl lutm slic t peri
-- 2009-07-11   232  10.1.03 K39 xc3s1000-4     8   25    0   15 s  5.3
--
-- Revision History: 
-- Date         Rev Version  Comment
-- 2009-06-01   221   1.0.5  BUGFIX: add RESET; don't clear tcnt on ibus reset
-- 2008-08-22   161   1.0.4  use iblib; add EI_ACK to proc_next sens. list
-- 2008-05-09   144   1.0.3  use intreq flop, use EI_ACK
-- 2008-01-20   112   1.0.2  fix proc_next sensitivity list; use BRESET
-- 2008-01-06   111   1.0.1  Renamed to ibd_kw11l (RRI_REQ not used)
-- 2008-01-05   110   1.0    Initial version 
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

use work.slvtypes.all;
use work.iblib.all;

-- ----------------------------------------------------------------------------
entity ibd_kw11l is                     -- ibus dev(loc): KW11-L (line clock)
                                        -- fixed address: 177546
  port (
    CLK : in slbit;                     -- clock
    CE_MSEC : in slbit;                 -- msec pulse
    RESET : in slbit;                   -- system reset
    BRESET : in slbit;                  -- ibus reset
    IB_MREQ : in ib_mreq_type;          -- ibus request
    IB_SRES : out ib_sres_type;         -- ibus response
    EI_REQ : out slbit;                 -- interrupt request
    EI_ACK : in slbit                   -- interrupt acknowledge
  );
end ibd_kw11l;

architecture syn of ibd_kw11l is

  constant ibaddr_kw11l : slv16 := conv_std_logic_vector(8#177546#,16);

  constant lks_ibf_ie :   integer :=  6;
  constant lks_ibf_moni : integer :=  7;

  constant twidth : natural  :=  5;
  constant tdivide : natural := 20;
  
  type regs_type is record              -- state registers
    ie : slbit;                         -- interrupt enable
    moni : slbit;                       -- monitor bit
    intreq : slbit;                     -- interrupt request
    tcnt : slv(twidth-1 downto 0);      -- timer counter
  end record regs_type;

  constant regs_init : regs_type := (
    '0',                                -- ie
    '1',                                -- moni (set on reset !!)
    '0',                                -- intreq
    (others=>'0')                       -- tcnt
  );

  signal R_REGS : regs_type := regs_init;
  signal N_REGS : regs_type := regs_init;

begin
  
  proc_regs: process (CLK)
  begin
    if CLK'event and CLK='1' then
      if BRESET = '1' then             -- BRESET is 1 for system and ibus reset
        R_REGS <= regs_init;
        if RESET = '0' then               -- if RESET=0 we do just an ibus reset
          R_REGS.tcnt <= N_REGS.tcnt;       -- don't clear msec tick counter
        end if;
     else
        R_REGS <= N_REGS;
      end if;
    end if;
  end process proc_regs;

  proc_next : process (R_REGS, IB_MREQ, CE_MSEC, EI_ACK)
    variable r : regs_type := regs_init;
    variable n : regs_type := regs_init;
    variable ibsel : slbit := '0';
    variable idout : slv16 := (others=>'0');
  begin

    r := R_REGS;
    n := R_REGS;

    ibsel := '0';
    idout := (others=>'0');
    
    -- ibus address decoder
    if IB_MREQ.req='1' and IB_MREQ.addr=ibaddr_kw11l(12 downto 1) then
      ibsel := '1';
    end if;

    -- ibus output driver
    if ibsel = '1' then
      idout(lks_ibf_ie)   := R_REGS.ie;
      idout(lks_ibf_moni) := R_REGS.moni;
    end if;

    -- ibus write transactions
    if ibsel='1' and IB_MREQ.we='1' and IB_MREQ.be0='1' then
      n.ie   := IB_MREQ.din(lks_ibf_ie);
      n.moni := IB_MREQ.din(lks_ibf_moni);
      if IB_MREQ.din(lks_ibf_ie)='0' or IB_MREQ.din(lks_ibf_moni)='0' then
        n.intreq := '0';
      end if;
    end if;
    
    -- other state changes
    if CE_MSEC = '1' then
      n.tcnt := unsigned(r.tcnt) + 1;
      if unsigned(r.tcnt) = tdivide-1 then
        n.tcnt := (others=>'0');
        n.moni := '1';
        if r.ie = '1' then
          n.intreq := '1';
        end if;
      end if;
    end if;

    if EI_ACK = '1' then
      n.intreq := '0';
    end if;
    
    N_REGS <= n;

    IB_SRES.dout <= idout;
    IB_SRES.ack  <= ibsel;
    IB_SRES.busy <= '0';
    
    EI_REQ <= r.intreq;
    
  end process proc_next;
  
end syn;
