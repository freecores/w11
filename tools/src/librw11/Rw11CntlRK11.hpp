// $Id: Rw11CntlRK11.hpp 509 2013-04-21 20:46:20Z mueller $
//
// Copyright 2013- by Walter F.J. Mueller <W.F.J.Mueller@gsi.de>
//
// This program is free software; you may redistribute and/or modify it under
// the terms of the GNU General Public License as published by the Free
// Software Foundation, either version 2, or at your option any later version.
//
// This program is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY, without even the implied warranty of MERCHANTABILITY
// or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
// for complete details.
// 
// Revision History: 
// Date         Rev Version  Comment
// 2013-04-20   508   1.0    Initial version
// 2013-02-10   485   0.1    First draft
// ---------------------------------------------------------------------------


/*!
  \file
  \version $Id: Rw11CntlRK11.hpp 509 2013-04-21 20:46:20Z mueller $
  \brief   Declaration of class Rw11CntlRK11.
*/

#ifndef included_Retro_Rw11CntlRK11
#define included_Retro_Rw11CntlRK11 1

#include "Rw11CntlBase.hpp"
#include "Rw11UnitRK11.hpp"

namespace Retro {

  class Rw11CntlRK11 : public Rw11CntlBase<Rw11UnitRK11,8> {
    public:

                    Rw11CntlRK11();
                   ~Rw11CntlRK11();

      void          Config(const std::string& name, uint16_t base, int lam);

      virtual void  Start();

      virtual bool  BootCode(size_t unit, std::vector<uint16_t>& code, 
                             uint16_t& aload, uint16_t& astart);

      virtual void  UnitSetup(size_t ind);

      virtual void  Dump(std::ostream& os, int ind=0, const char* text=0) const;

    // some constants (also defined in cpp)
      static const uint16_t kIbaddr = 0177400; //!< RK11 default address
      static const int      kLam    = 4;       //!< RK11 default lam

      static const uint16_t kRKDS = 000; //!< RKDS register address offset
      static const uint16_t kRKER = 002; //!< RKER register address offset
      static const uint16_t kRKCS = 004; //!< RKCS register address offset
      static const uint16_t kRKWC = 006; //!< RKWC register address offset
      static const uint16_t kRKBA = 010; //!< RKBA register address offset
      static const uint16_t kRKDA = 012; //!< RKDA register address offset
      static const uint16_t kRKMR = 014; //!< RKMR register address offset

      static const uint16_t kProbeOff = kRKCS; //!< probe address offset (rkcs)
      static const bool     kProbeInt = true;  //!< probe int active
      static const bool     kProbeRem = true;  //!< probr rem active

      static const uint16_t kRKDS_M_ID   = 0160000; //!< ID: drive number
      static const uint16_t kRKDS_V_ID   = 13;
      static const uint16_t kRKDS_B_ID   = 0007;
      static const uint16_t kRKDS_M_HDEN = kWBit11; //!< HDEN: high density drv
      static const uint16_t kRKDS_M_DRU  = kWBit10; //!< DRU: drive unsafe
      static const uint16_t kRKDS_M_SIN  = kWBit09; //!< SIN: seek incomplete
      static const uint16_t kRKDS_M_SOK  = kWBit08; //!< SOK: sector counter OK
      static const uint16_t kRKDS_M_DRY  = kWBit07; //!< DRY: drive ready
      static const uint16_t kRKDS_M_ADRY = kWBit06; //!< ADRY: access ready
      static const uint16_t kRKDS_M_WPS  = kWBit05; //!< WPS: write protect
      static const uint16_t kRKDS_B_SC   = 0017;    //!< SC: sector counter

      static const uint16_t kRKER_M_DRE  = kWBit15;
      static const uint16_t kRKER_M_OVR  = kWBit14;
      static const uint16_t kRKER_M_WLO  = kWBit13;
      static const uint16_t kRKER_M_PGE  = kWBit11;
      static const uint16_t kRKER_M_NXM  = kWBit10;
      static const uint16_t kRKER_M_NXD  = kWBit07;
      static const uint16_t kRKER_M_NXC  = kWBit06;
      static const uint16_t kRKER_M_NXS  = kWBit05;
      static const uint16_t kRKER_M_CSE  = kWBit01;
      static const uint16_t kRKER_M_WCE  = kWBit00;

      static const uint16_t kRKCS_M_MAINT= kWBit12;
      static const uint16_t kRKCS_M_IBA  = kWBit11;
      static const uint16_t kRKCS_M_FMT  = kWBit10;
      static const uint16_t kRKCS_M_RWA  = kWBit09;
      static const uint16_t kRKCS_M_SSE  = kWBit08;
      static const uint16_t kRKCS_M_MEX  = 000060;
      static const uint16_t kRKCS_V_MEX  = 4;
      static const uint16_t kRKCS_B_MEX  = 0003;
      static const uint16_t kRKCS_V_FUNC = 1;
      static const uint16_t kRKCS_B_FUNC = 0007;
      static const uint16_t kRKCS_CRESET = 0;
      static const uint16_t kRKCS_WRITE  = 1;
      static const uint16_t kRKCS_READ   = 2;
      static const uint16_t kRKCS_WCHK   = 3;
      static const uint16_t kRKCS_SEEK   = 4;
      static const uint16_t kRKCS_RCHK   = 5;
      static const uint16_t kRKCS_DRESET = 6;
      static const uint16_t kRKCS_WLOCK  = 7;
      static const uint16_t kRKCS_M_GO   = kWBit00;

      static const uint16_t kRKDA_M_DRSEL= 0160000;
      static const uint16_t kRKDA_V_DRSEL= 13;
      static const uint16_t kRKDA_B_DRSEL= 0007;
      static const uint16_t kRKDA_M_CYL  = 0017740;
      static const uint16_t kRKDA_V_CYL  =  5;
      static const uint16_t kRKDA_B_CYL  = 0377;
      static const uint16_t kRKDA_M_SUR  = 0000020;
      static const uint16_t kRKDA_V_SUR  =  4;
      static const uint16_t kRKDA_B_SUR  = 0001;
      static const uint16_t kRKDA_B_SC   = 0017;

      static const uint16_t kRKMR_M_RID  = 0160000;
      static const uint16_t kRKMR_V_RID  = 13;
      static const uint16_t kRKMR_M_CRDONE= kWBit11;
      static const uint16_t kRKMR_M_SBCLR = kWBit10;
      static const uint16_t kRKMR_M_CRESET= kWBit09;
      static const uint16_t kRKMR_M_FDONE = kWBit08;

    protected:
      int           AttnHandler(const RlinkServer::AttnArgs& args);
      int           RdmaHandler();
      void          LogRker(uint16_t rker);
    
    protected:
      size_t        fPC_rkwc;               //!< PrimClist: rkwc index
      size_t        fPC_rkba;               //!< PrimClist: rkba index
      size_t        fPC_rkda;               //!< PrimClist: rkda index
      size_t        fPC_rkmr;               //!< PrimClist: rkmr index
      size_t        fPC_rkcs;               //!< PrimClist: rkcs index

      bool          fRd_busy;               //!< Rdma: busy flag
      uint16_t      fRd_rkcs;               //!< Rdma: request rkcs
      uint16_t      fRd_rkda;               //!< Rdma: request rkda
      uint32_t      fRd_addr;               //!< Rdma: current addr
      uint32_t      fRd_lba;                //!< Rdma: current lba
      uint32_t      fRd_nwrd;               //!< Rdma: current nwrd
      bool          fRd_ovr;                //!< Rdma: overrun condition found
  };
  
} // end namespace Retro

//#include "Rw11CntlRK11.ipp"

#endif
