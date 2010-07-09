-- $Id: tb_rri_core.vhd 314 2010-07-09 17:38:41Z mueller $
--
-- Copyright 2007- by Walter F.J. Mueller <W.F.J.Mueller@gsi.de>
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
-- Module Name:    tb_rri_core
-- Description:    Configuration for tb_rri_core for tb_rri.
--
-- Dependencies:   tbd_rri_gen
--
-- To test:        rri_core
--
-- Target Devices: generic
--
-- Verified (with tb_rri_stim.dat):
-- Date         Rev  Code  ghdl  ise          Target     Comment
-- 2007-11-02    93  _tsim 0.26  8.2.03 I34   xc3s1000   d:ok
-- 2007-10-12    88  _ssim 0.26  8.1.03 I27   xc3s1000   c:ok
-- 2007-10-12    88  -     0.26  -            -          c:ok
--
-- Revision History: 
-- Date         Rev Version  Comment
-- 2007-11-25    98   1.0.1  use entity rather arch name to switch core/serport
-- 2007-07-08    65   1.0    Initial version 
------------------------------------------------------------------------------

configuration tb_rri_core of tb_rri is

  for sim
    for all : tbd_rri_gen
      use entity work.tbd_rri_core;
    end for;
  end for;

end tb_rri_core;
