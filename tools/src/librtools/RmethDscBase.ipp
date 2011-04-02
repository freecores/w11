// $Id: RmethDscBase.ipp 365 2011-02-28 07:28:26Z mueller $
//
// Copyright 2011- by Walter F.J. Mueller <W.F.J.Mueller@gsi.de>
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
// 2011-02-11   360   1.1    templetize arglist type
// 2011-02-06   359   1.0    Initial version
// ---------------------------------------------------------------------------

/*!
  \file
  \version $Id: RmethDscBase.ipp 365 2011-02-28 07:28:26Z mueller $
  \brief   Implemenation (inline) of RmethDscBase
*/

// all method definitions in namespace Retro (avoid using in includes...)
namespace Retro {

/*!
  \class RmethDscBase 
  \brief FIXME_docs
*/

//------------------------------------------+-----------------------------------
/*!
  \brief Default constructor.
*/

template <class TA>
inline RmethDscBase<TA>::RmethDscBase()
{}

//------------------------------------------+-----------------------------------
/*!
  \brief Copy constructor.
*/

template <class TA>
inline RmethDscBase<TA>::RmethDscBase(const RmethDscBase& rhs)
{}

//------------------------------------------+-----------------------------------
/*!
  \brief Destructor.
*/

template <class TA>
inline RmethDscBase<TA>::~RmethDscBase()
{}


} // end namespace Retro
