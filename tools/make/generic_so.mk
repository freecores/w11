# $Id: generic_so.mk 354 2011-01-09 22:38:53Z mueller $
#
#  Revision History: 
# Date         Rev Version  Comment
# 2011-01-09   354   1.0    Initial version (from wrepo/make/generic_so.mk)
#---
#
# Build a sharable library and an archive
#
# Before including, defined the following variables:
#   SOPATH    relative directory path of the library (def: $RETROBASE/tools/lib)
#   SONAME    name of the library
#   SOMAJV    major version number
#   SOMINV    minor version number
#
ifndef SOPATH
SOPATH     = $(RETROBASE)/tools/lib
endif
#
SOFILE     = lib$(SONAME).so
SOFILEV    = lib$(SONAME).so.$(SOMAJV)
SOFILEVV   = lib$(SONAME).so.$(SOMAJV).$(SOMINV)
AFILE      = lib$(SONAME).a
#
.PHONY : libs
libs : $(SOPATH)/$(AFILE) $(SOPATH)/$(SOFILEVV) 
#
# Build the sharable library
#
$(SOPATH)/$(SOFILEVV) : $(OBJ_all)
	if [ ! -d $(SOPATH) ]; then mkdir $(SOPATH); fi
	$(CXX) -shared -Wl,-soname,$(SOFILEV) -o $(SOPATH)/$(SOFILEVV) \
		$(OBJ_all) $(LDLIBS)
	(cd $(SOPATH); rm -f $(SOFILE)   $(SOFILEV))
	(cd $(SOPATH); ln -s $(SOFILEVV) $(SOFILEV))
	(cd $(SOPATH); ln -s $(SOFILEV)  $(SOFILE))
#
# Build an archive
#
$(SOPATH)/$(AFILE) : $(OBJ_all)
	if [ ! -d $(SOPATH) ]; then mkdir $(SOPATH); fi
	ar -scruv $(SOPATH)/$(AFILE) $?
#
