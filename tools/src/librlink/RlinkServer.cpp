// $Id: RlinkServer.cpp 513 2013-05-01 14:02:06Z mueller $
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
// 2013-05-01   513   1.0.2  fTraceLevel now uint32_t
// 2013-04-21   509   1.0.1  add Resume(), reorganize server start handling
// 2013-03-06   495   1.0    Initial version
// 2013-01-12   474   0.5    First draft
// ---------------------------------------------------------------------------

/*!
  \file
  \version $Id: RlinkServer.cpp 513 2013-05-01 14:02:06Z mueller $
  \brief   Implemenation of RlinkServer.
*/

#include "boost/thread/locks.hpp"
#include "boost/bind.hpp"

#include "librtools/Rexception.hpp"
#include "librtools/RosFill.hpp"
#include "librtools/RosPrintf.hpp"
#include "librtools/RosPrintBvi.hpp"
#include "librtools/Rexception.hpp"
#include "librtools/RlogMsg.hpp"

#include "RlinkServer.hpp"

using namespace std;

/*!
  \class Retro::RlinkServer
  \brief FIXME_docs
*/

// all method definitions in namespace Retro
namespace Retro {

//------------------------------------------+-----------------------------------
//! Default constructor

RlinkServer::RlinkServer()
  : fspConn(),
    fContext(),
    fAttnDsc(),
    fActnList(),
    fWakeupEvent(),
    fELoop(this),
    fServerThread(),
    fAttnSeen(false),
    fAttnPatt(0),
    fTraceLevel(0),
    fStats()
{
  fContext.SetStatus(0,
             ~(RlinkCommand::kStat_M_RbNak|RlinkCommand::kStat_M_RbErr));

  fELoop.AddPollHandler(boost::bind(&RlinkServer::WakeupHandler, this, _1), 
                        fWakeupEvent, POLLIN);

  // Statistic setup
  fStats.Define(kStatNEloopWait,"NEloopWait","event loop turns (wait)");
  fStats.Define(kStatNEloopPoll,"NEloopPoll","event loop turns (poll)");
  fStats.Define(kStatNWakeupEvt,"NWakeupEvt","Wakeup events");
  fStats.Define(kStatNRlinkEvt, "NRlinkEvt", "Rlink data events");
  fStats.Define(kStatNAttnRead, "NAttnRead", "Attn read commands");
  fStats.Define(kStatNAttn00,   "NAttn00",   "Attn bit  0 set");
  fStats.Define(kStatNAttn01,   "NAttn01",   "Attn bit  1 set");
  fStats.Define(kStatNAttn02,   "NAttn02",   "Attn bit  2 set");
  fStats.Define(kStatNAttn03,   "NAttn03",   "Attn bit  3 set");
  fStats.Define(kStatNAttn04,   "NAttn04",   "Attn bit  4 set");
  fStats.Define(kStatNAttn05,   "NAttn05",   "Attn bit  5 set");
  fStats.Define(kStatNAttn06,   "NAttn06",   "Attn bit  6 set");
  fStats.Define(kStatNAttn07,   "NAttn07",   "Attn bit  7 set");
  fStats.Define(kStatNAttn08,   "NAttn08",   "Attn bit  8 set");
  fStats.Define(kStatNAttn09,   "NAttn09",   "Attn bit  9 set");
  fStats.Define(kStatNAttn10,   "NAttn10",   "Attn bit 10 set");
  fStats.Define(kStatNAttn11,   "NAttn11",   "Attn bit 11 set");
  fStats.Define(kStatNAttn12,   "NAttn12",   "Attn bit 12 set");
  fStats.Define(kStatNAttn13,   "NAttn13",   "Attn bit 13 set");
  fStats.Define(kStatNAttn14,   "NAttn14",   "Attn bit 14 set");
  fStats.Define(kStatNAttn15,   "NAttn15",   "Attn bit 15 set");
}

//------------------------------------------+-----------------------------------
//! Destructor

RlinkServer::~RlinkServer()
{
  Stop();
  if (fspConn) fspConn->SetServer(0);
}

//------------------------------------------+-----------------------------------
//! FIXME_docs

void RlinkServer::SetConnect(const boost::shared_ptr<RlinkConnect>& spconn)
{
  if (!fspConn && !spconn) return;          // allow 0 = 0 ...
  if (fspConn)
    throw Rexception("RlinkServer::SetConnect()",
                     "Bad state: fspConn already set");
  if (!spconn)
    throw Rexception("RlinkServer::SetConnect()", "Bad args: spconn==0");
  
  fspConn = spconn;
  fELoop.SetLogFile(fspConn->LogFileSPtr());
  fspConn->SetServer(this);
  return;
}

//------------------------------------------+-----------------------------------
//! FIXME_docs

void RlinkServer::AddAttnHandler(const attnhdl_t& attnhdl, uint16_t mask,
                                 void* cdata)
{
  if (mask == 0)
    throw Rexception("RlinkServer::AddAttnHandler()", "Bad args: mask == 0");

  boost::lock_guard<RlinkConnect> lock(*fspConn);

  AttnId id(mask, cdata);
  for (size_t i=0; i<fAttnDsc.size(); i++) {
    if (fAttnDsc[i].fId == id) {
      throw Rexception("RlinkServer::AddAttnHandler()", 
                       "Bad args: duplicate handler");
    }
  }
  fAttnDsc.push_back(AttnDsc(attnhdl, id));

  return;
}

//------------------------------------------+-----------------------------------
//! FIXME_docs

void RlinkServer::RemoveAttnHandler(uint16_t mask, void* cdata)
{    
  boost::lock_guard<RlinkConnect> lock(*fspConn);

  AttnId id(mask, cdata);
  for (size_t i=0; i<fAttnDsc.size(); i++) {
    if (fAttnDsc[i].fId == id) {
      fAttnDsc.erase(fAttnDsc.begin()+i);
      return;
    }
  }

  throw Rexception("RlinkServer::RemoveAttnHandler()", 
                   "Bad args: unknown handler");
}

//------------------------------------------+-----------------------------------
//! FIXME_docs

void RlinkServer::QueueAction(const actnhdl_t& actnhdl)
{
  boost::lock_guard<RlinkConnect> lock(*fspConn);
  fActnList.push_back(actnhdl);
  if (IsActiveOutside()) Wakeup();
  return;
}

//------------------------------------------+-----------------------------------
//! FIXME_docs
 
void RlinkServer::AddPollHandler(const pollhdl_t& pollhdl,
                                        int fd, short events)
{
  boost::lock_guard<RlinkConnect> lock(*fspConn);
  fELoop.AddPollHandler(pollhdl, fd, events);
  if (IsActiveOutside()) Wakeup();
  return;
}
 
//------------------------------------------+-----------------------------------
//! FIXME_docs
 
bool RlinkServer::TestPollHandler(int fd, short events)
{
  boost::lock_guard<RlinkConnect> lock(*fspConn);
  return fELoop.TestPollHandler(fd, events);
}

//------------------------------------------+-----------------------------------
//! FIXME_docs

void RlinkServer::RemovePollHandler(int fd, short events, bool nothrow)
{
  boost::lock_guard<RlinkConnect> lock(*fspConn);
  fELoop.RemovePollHandler(fd, events,nothrow);
  if (IsActiveOutside()) Wakeup();
  return;
}

//------------------------------------------+-----------------------------------
//! FIXME_docs

void RlinkServer::RemovePollHandler(int fd)
{
  boost::lock_guard<RlinkConnect> lock(*fspConn);
  fELoop.RemovePollHandler(fd);
  if (IsActiveOutside()) Wakeup();
  return;
}

//------------------------------------------+-----------------------------------
//! FIXME_docs

void RlinkServer::Start()
{
  StartOrResume(false);
  return;
}

//------------------------------------------+-----------------------------------
//! FIXME_docs

void RlinkServer::Stop()
{    
  fELoop.Stop();
  Wakeup();
  fServerThread.join();
  return;
}

//------------------------------------------+-----------------------------------
//! FIXME_docs

void RlinkServer::Resume()
{    
  StartOrResume(true);
  return;
}

//------------------------------------------+-----------------------------------
//! FIXME_docs

void RlinkServer::Wakeup()
{    
  uint64_t one(1);
  int irc = write(fWakeupEvent, &one, sizeof(one));
  if (irc < 0) 
    throw Rexception("RlinkServer::Wakeup()", 
                     "write() to eventfd failed: ", errno);
  return;
}

//------------------------------------------+-----------------------------------
//! FIXME_docs

void RlinkServer::SignalAttn()
{    
  boost::lock_guard<RlinkConnect> lock(*fspConn);
  fAttnSeen = true;
  Wakeup();
  return;
}

//------------------------------------------+-----------------------------------
//! FIXME_docs

bool RlinkServer::IsActive() const
{    
  return fServerThread.get_id() != boost::thread::id();
}

//------------------------------------------+-----------------------------------
//! FIXME_docs

bool RlinkServer::IsActiveInside() const
{
  return IsActive() && boost::this_thread::get_id() == fServerThread.get_id();
}

//------------------------------------------+-----------------------------------
//! FIXME_docs

bool RlinkServer::IsActiveOutside() const
{
  return IsActive() && boost::this_thread::get_id() != fServerThread.get_id();
}

//------------------------------------------+-----------------------------------
//! FIXME_docs

void RlinkServer::SetTraceLevel(uint32_t level)
{
  fTraceLevel = level;
  fELoop.SetTraceLevel(level);
  return;
}

//------------------------------------------+-----------------------------------
//! FIXME_docs

void RlinkServer::Print(std::ostream& os) const
{
  os << "RlinkServer::Print(std::ostream& os)" << endl;
  return;
}

//------------------------------------------+-----------------------------------
//! FIXME_docs

void RlinkServer::Dump(std::ostream& os, int ind, const char* text) const
{
  // FIXME_code: is that thread safe ??? fActnList.size() ???
  RosFill bl(ind);
  os << bl << (text?text:"--") << "RlinkServer @ " << this << endl;
  os << bl << "  fspConn:         " <<  fspConn << endl;

  os << bl << "  fAttnDsc:        " << endl;
  for (size_t i=0; i<fAttnDsc.size(); i++) 
    os << bl << "    [" << RosPrintf(i,"d",3) << "]: "
       << RosPrintBvi(fAttnDsc[i].fId.fMask,16)
       << ", " << fAttnDsc[i].fId.fCdata << endl;
  os << bl << "  fActnList.size:  " << fActnList.size() << endl;
  fELoop.Dump(os, ind+2, "fELoop");
  os << bl << "  fServerThread:   " << fServerThread.get_id() << endl;
  os << bl << "  fAttnSeen:       " << fAttnSeen << endl;
  os << bl << "  fAttnPatt:       " << RosPrintBvi(fAttnPatt,16) << endl;
  fStats.Dump(os, ind+2, "fStats: ");
  return;
}

//------------------------------------------+-----------------------------------
//! FIXME_docs

void RlinkServer::StartOrResume(bool resume)
{
  if (IsActive())
    throw Rexception("RlinkServer::StartOrResume()", 
                     "Bad state: server thread already running");
  if (!fspConn->IsOpen())
    throw Rexception("RlinkServer::StartOrResume()", 
                     "Bad state: RlinkConnect not open");

  boost::lock_guard<RlinkConnect> lock(Connect());
  // enable attn comma send
  RlinkCommandList clist;
  if (!resume) clist.AddAttn();
  clist.AddInit(RlinkCommand::kRbaddr_IInt, RlinkCommand::kIInt_M_AnEna);
  Exec(clist);

  // setup poll handler for Rlink traffic
  int rlinkfd = fspConn->Port()->FdRead();
  if (!fELoop.TestPollHandler(rlinkfd, POLLIN))
    fELoop.AddPollHandler(boost::bind(&RlinkServer::RlinkHandler, this, _1), 
                          rlinkfd, POLLIN);
  
  // and start server thread
  fServerThread = boost::thread(boost::bind(&RlinkServerEventLoop::EventLoop,
                                            &fELoop));

  if (resume) {
    RerrMsg emsg;
    if (!Connect().SndAttn(emsg)) {
      RlogMsg lmsg(LogFile(), 'E');
      lmsg << "attn send for server resume failed:" << emsg;
    }
  }

  return;
}

//------------------------------------------+-----------------------------------
//! FIXME_docs

void RlinkServer::CallAttnHandler()
{
  if (fAttnSeen) {
    boost::lock_guard<RlinkConnect> lock(*fspConn);
    RlinkCommandList clist;
    clist.AddAttn();
    fStats.Inc(kStatNAttnRead);
    Exec(clist);
    // FIXME_code: handle errors: bool ok = 
    uint16_t nattn = clist[0].Data();
    fAttnPatt |= nattn;
    for (size_t i=0; i<16; i++) {
      if (nattn & (uint16_t(1)<<i)) fStats.Inc(kStatNAttn00+i);
    }
    fAttnSeen = false;
  }
  
  // multiple handlers may be called for one attn bit
  uint16_t hdone = 0;
  for (size_t i=0; i<fAttnDsc.size(); i++) {
    uint16_t hmatch = fAttnPatt & fAttnDsc[i].fId.fMask;
    if (hmatch) {
      AttnArgs args(fAttnPatt, fAttnDsc[i].fId.fMask);
      // FIXME_code: return code not used, yet
      boost::lock_guard<RlinkConnect> lock(*fspConn);
      fAttnDsc[i].fHandler(args);
      hdone |= hmatch;
    }
  }
  fAttnPatt &= ~hdone;                      // clear handled bits

  if (fAttnPatt && fTraceLevel>0) {
    RlogMsg lmsg(LogFile(), 'I');
    lmsg << "eloop: unhandled attn, mask="
         << RosPrintBvi(fAttnPatt,16) << endl;
  }
  
  fAttnPatt = 0;

  return;
}

//------------------------------------------+-----------------------------------
//! FIXME_docs

void RlinkServer::CallActnHandler()
{
  if (!ActnPending()) return;

  // call first action
  boost::lock_guard<RlinkConnect> lock(*fspConn);

  int irc = fActnList.front()();

  // if irc>0 requeue to end, otherwise drop
  if (irc > 0) {
    fActnList.splice(fActnList.end(), fActnList, fActnList.begin());
  } else {
    fActnList.pop_front();
  }

  return;
}

//------------------------------------------+-----------------------------------
//! FIXME_docs

int RlinkServer::WakeupHandler(const pollfd& pfd)
{
  fStats.Inc(kStatNWakeupEvt);

  // bail-out and cancel handler if poll returns an error event
  if (pfd.revents & (~pfd.events)) return -1;

  uint64_t buf;
  int irc = read(fWakeupEvent, &buf, sizeof(buf));
  if (irc < 0) 
    throw Rexception("RlinkServer::WakeupHandler()", 
                     "read() from eventfd failed: ", errno);
  return 0;
}

//------------------------------------------+-----------------------------------
//! FIXME_docs

int RlinkServer::RlinkHandler(const pollfd& pfd)
{
  fStats.Inc(kStatNRlinkEvt);

  // bail-out and cancel handler if poll returns an error event
  if (pfd.revents & (~pfd.events)) return -1;

  boost::lock_guard<RlinkConnect> lock(*fspConn);
  RerrMsg emsg;
  int irc = fspConn->PollAttn(emsg);
  if (irc > 0) {
    fAttnSeen = true;
  }

  return 0;
}

} // end namespace Retro
