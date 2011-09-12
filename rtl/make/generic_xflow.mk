# $Id: generic_xflow.mk 406 2011-08-14 21:06:44Z mueller $
#
#  Revision History: 
# Date         Rev Version  Comment
# 2011-08-14   406   1.7.1  use isemsg_filter; new %.mfsum target
# 2011-08-13   405   1.7    renamed, moved to rtl/make;
# 2011-07-17   394   1.6.2  add rm *.svf to ise_clean rule
# 2011-07-11   392   1.6.1  use config_wrapper, support jtag via svf generation
# 2011-06-26   385   1.6    use ISE_PATH for vbomconv -xst_prj
# 2010-11-26   340   1.5.8  fix path for .opt defaults (now rtl/vlib)
# 2010-05-06   289   1.5.7  add xilinx_tsim_xon support
# 2010-04-24   282   1.5.6  add %.impact rule to run impact_wrapper
# 2010-04-17   278   1.4.5  add '|| true' after grep in diag summary to prevent
#                           a make abort in case no diags are seen
# 2010-04-02   273   1.4.4  add -I{RETROBASE} to ucf_cpp processing rules
# 2010-03-14   268   1.4.3  add XFLOWOPT_SYN and XFLOWOPT_IMP
# 2009-11-21   252   1.4.2  use bitgen directly, use ISE_USERID
# 2007-12-17   102   1.4.1  fix %.dep_ucf_cpp : %.ucf_cpp rule
# 2007-12-16   101   1.4    add ucf_cpp rules
# 2007-12-09   100   1.3.7  ifndef define ISE_PATH to xc3s1000-ft256-4
# 2007-11-02    94   1.3.6  use .SECONDARY to keep intermediate files
# 2007-10-28    93   1.3.5  call xst_count_bels -xsts when _ssim is generated
# 2007-10-12    88   1.3.4  support <design>.xcf files, if provided
# 2007-10-06    87   1.3.3  remove *_twr.log in clean
# 2007-07-20    67   1.3.2  handle local/global xst_vhdl.opt
# 2007-07-15    66   1.3.1  add rule "%.ngc: ../%.vbom" to support _*sim in ./tb
#                           add XST diagnostics summary at end of listing
# 2007-07-06    64   1.3    all vbom based now
# 2007-06-16    57   1.2.1  cleanup ghdl_clean handling (rm _[sft]sim)
# 2007-06-10    52   1.2    reorganized svn directory structure
# 2007-06-10    51   1.1    consolidate test bench generation
# 2007-06-03    45   1.0    Initial version
#---
#
# setup default board (for impact), device and userid (for bitgen)
#
ifndef ISE_BOARD
ISE_BOARD = s3board
endif
#
ifndef ISE_PATH
ISE_PATH  = xc3s1000-ft256-4
endif
#
ifndef ISE_USERID
ISE_USERID = 0xffffffff
endif
#
# setup defaults for xflow option files for synthesis and implementation
#
ifndef XFLOWOPT_SYN
XFLOWOPT_SYN = syn_s3_speed.opt
endif
#
ifndef XFLOWOPT_IMP
XFLOWOPT_IMP = imp_s3_speed.opt
endif
#
XFLOW    = xflow -p ${ISE_PATH} 
#
# $@ first target
# $< first dependency
# $* stem in rule match
#
# when chaining, don't delete 'expensive' intermediate files:
.SECONDARY : 
#
# Synthesize (xst)
#   input:   %.vbom     vbom project description
#   output:  %.ngc
#            %_xst.log  xst log file
#
%.ngc: %.vbom
	if [ ! -d ./ise ]; then mkdir ./ise; fi
	(cd ./ise; vbomconv --ise_path=${ISE_PATH} --xst_prj ../$< > $*.prj)
	(cd ./ise; touch $*.xcf)
	if [ -r  $*.xcf ]; then cp $*.xcf ./ise; fi
	if [ -r ${RETROBASE}/rtl/make/${XFLOWOPT_SYN} ]; then \
		cp ${RETROBASE}/rtl/make/${XFLOWOPT_SYN} ./ise; fi
	if [ -r ${XFLOWOPT_SYN} ]; then cp ${XFLOWOPT_SYN} ./ise; fi
	${XFLOW} -wd ise -synth ${XFLOWOPT_SYN} $*.prj 
	(cd ./ise; chmod -x *.* )
	if [ -r ./ise/$*.ngc ]; then cp -p ./ise/$*.ngc .; fi
	if [ -r ./ise/$*_xst.log ]; then cp -p ./ise/$*_xst.log .; fi
	@ echo "==============================================================="
	@ echo "*     XST Diagnostic Summary                                  *"
	@ echo "==============================================================="
	@ if [ -r $*.mfset ]; then isemsg_filter xst $*.mfset $*_xst.log; fi
	@ if [ ! -r $*.mfset ]; then grep -i -A 1 ":.*:" $*_xst.log || true; fi
	@ echo "==============================================================="
#
# the following rule needed to generate an %_*sim.vhd in a ./tb sub-directory
# it will look for a matching vbom in the parent directory
%.ngc: ../%.vbom
	if [ ! -d ./ise ]; then mkdir ./ise; fi
	(cd ./ise; vbomconv --xst_prj ../$< > $*.prj)
	(cd ./ise; touch $*.xcf)
	if [ -r  $*.xcf ]; then cp $*.xcf ./ise; fi
	if [ -r ${RETROBASE}/rtl/make/${XFLOWOPT_SYN} ]; then \
		cp ${RETROBASE}/rtl/make/${XFLOWOPT_SYN} ./ise; fi
	if [ -r ${XFLOWOPT_SYN} ]; then cp ${XFLOWOPT_SYN} ./ise; fi
	${XFLOW} -wd ise -synth ${XFLOWOPT_SYN} $*.prj 
	(cd ./ise; chmod -x *.* )
	if [ -r ./ise/$*.ngc ]; then cp -p ./ise/$*.ngc .; fi
	if [ -r ./ise/$*_xst.log ]; then cp -p ./ise/$*_xst.log .; fi
	@ echo "==============================================================="
	@ echo "*     XST Diagnostic Summary                                  *"
	@ echo "==============================================================="
	@ if [ -r $*.mfset ]; then isemsg_filter xst $*.mfset $*_xst.log; fi
	@ if [ ! -r $*.mfset ]; then grep -i -A 1 ":.*:" $*_xst.log || true; fi
	@ echo "==============================================================="
#
# Implement 1 (map+par)
#   input:   %.ngc
#            %.ucf      constraint file (if available)
#   output:  %.ncd
#            %.pcf
#            %_tra.log  translate (ngdbuild) log file (renamed %.bld)
#            %_map.log  map log file                  (renamed %_map.mrp)
#            %_par.log  par log file                  (renamed %.par)
#            %_pad.log  pad file                      (renamed %_pad.txt)
#            %_twr.log  trce log file                 (renamed %.twr)
#
%.ncd %.pcf: %.ngc
	if [ ! -d ./ise ]; then mkdir ./ise; fi
	if [ -r $*.ngc ]; then cp -p $*.ngc ./ise; fi
	if [ -r $*.ucf ]; then cp -p $*.ucf ./ise; fi
	if [ -r ${RETROBASE}/rtl/make/${XFLOWOPT_IMP} ]; then \
		cp ${RETROBASE}/rtl/make/${XFLOWOPT_IMP} ./ise; fi
	if [ -r ${XFLOWOPT_IMP} ]; then cp -p ${XFLOWOPT_IMP} ./ise; fi
	${XFLOW} -wd ise -implement ${XFLOWOPT_IMP} $<
	(cd ./ise; chmod -x *.* )
	if [ -r ./ise/$*.ncd ]; then cp -p ./ise/$*.ncd .; fi
	if [ -r ./ise/$*.pcf ]; then cp -p ./ise/$*.pcf .; fi
	if [ -r ./ise/$*.bld ]; then cp -p ./ise/$*.bld ./$*_tra.log; fi
	if [ -r ./ise/$*_map.mrp ]; then cp -p ./ise/$*_map.mrp ./$*_map.log; fi
	if [ -r ./ise/$*.par ]; then cp -p ./ise/$*.par ./$*_par.log; fi
	if [ -r ./ise/$*_pad.txt ]; then cp -p ./ise/$*_pad.txt ./$*_pad.log; fi
	if [ -r ./ise/$*.twr ]; then cp -p ./ise/$*.twr ./$*_twr.log; fi
#
# Implement 2 (bitgen)
#   input:   %.ncd      
#   output:  %.bit
#            %.msk
#            %_bgn.log  bitgen log file    (renamed %.bgn)
#
%.bit: %.ncd
	if [ ! -d ./ise ]; then mkdir ./ise; fi
	if [ -r $*.ncd ]; then cp -p $*.ncd ./ise; fi
	(cd ./ise; bitgen -l -w -m -g ReadBack -g UserId:${ISE_USERID} -intstyle xflow $*.ncd)
	(cd ./ise; chmod -x *.* )
	if [ -r ./ise/$*.bit ]; then cp -p ./ise/$*.bit .; fi
	if [ -r ./ise/$*.msk ]; then cp -p ./ise/$*.msk .; fi
	if [ -r ./ise/$*.bgn ]; then cp -p ./ise/$*.bgn ./$*_bgn.log; fi
#
# Create svf from bitstream
#   input:   %.bit
#   output:  %.svf
#
%.svf: %.bit
	config_wrapper --board=${ISE_BOARD} --path=${ISE_PATH} bit2svf $*.bit

#
# Configure FPGA with impact
#   input:   %.bit
#   output:  .PHONY
#
%.iconfig: %.bit
	config_wrapper --board=${ISE_BOARD} --path=${ISE_PATH} iconfig $*.bit

#
# Configure FPGA with jtag
#   input:   %.svf
#   output:  .PHONY
#
%.jconfig: %.svf
	config_wrapper --board=${ISE_BOARD} --path=${ISE_PATH} jconfig $*.svf

#
# Print log file summary
#   input:   %_*.log (not depended)
#   output:  .PHONY
%.mfsum: %.mfset
	@ echo "=== XST summary ============================================="
	@ if [ -r $*_xst.log ]; then isemsg_filter xst $*.mfset $*_xst.log; fi
	@ echo "=== Translate summary ======================================="
	@ if [ -r $*_tra.log ]; then isemsg_filter tra $*.mfset $*_tra.log; fi
	@ echo "=== MAP summary ============================================="
	@ if [ -r $*_map.log ]; then isemsg_filter map $*.mfset $*_map.log; fi
	@ echo "=== PAR summary ============================================="
	@ if [ -r $*_par.log ]; then isemsg_filter par $*.mfset $*_par.log; fi
	@ echo "=== Bitgen summary =========================================="
	@ if [ -r $*_bgn.log ]; then isemsg_filter bgn $*.mfset $*_bgn.log; fi

#
#
#
# Post-XST simulation model (netgen -sim; UNISIM based)
#   input:   %.ngc    
#   output:  %_ssim.vhd
#            %_ngn_ssim.log  netgen log file    (renamed %.nlf)
#
%_ssim.vhd: %.ngc
	if [ ! -d ./ise ]; then mkdir ./ise; fi
	if [ -r $*.ngc ]; then cp -p $*.ngc ./ise; fi
	(cd ise; netgen -sim  -intstyle xflow -ofmt vhdl -w $*.ngc)
	(cd ./ise; chmod -x *.* )
	if [ -r ./ise/$*.vhd ]; then cp -p ./ise/$*.vhd ./$*_ssim.vhd; fi
	if [ -r ./ise/$*.nlf ]; then cp -p ./ise/$*.nlf ./$*_ngn_ssim.log; fi
	if [ -r $*_ssim.vhd ]; then xst_count_bels -xsts $*_ssim.vhd; fi
#
# Post-XST simulation model (netgen -sim; SIMPRIM based)
#   input:   %.ngc    
#   output:  %_fsim.vhd
#            %_ngn_fsim.log  netgen log file    (renamed %.nlf)
#
%_fsim.vhd: %.ngc
	if [ ! -d ./ise ]; then mkdir ./ise; fi
	if [ -r $*.ngc ]; then cp -p $*.ngc ./ise; fi
	(cd ise; ngdbuild -p ${ISE_PATH} -nt timestamp -intstyle xflow \
	$*.ngc $*.ngd)
	(cd ise; netgen -sim -intstyle xflow -ofmt vhdl -w $*.ngd)
	(cd ./ise; chmod -x *.* )
	if [ -r ./ise/$*.vhd ]; then cp -p ./ise/$*.vhd ./$*_fsim.vhd; fi
	if [ -r ./ise/$*.nlf ]; then cp -p ./ise/$*.nlf ./$*_ngn_fsim.log; fi
#
# Post-par timing simulation model (netgen -sim)
#   input:   %.ncd      
#   output:  %_tsim.vhd
#            %_ngn_tsim.log  netgen log file    (renamed time_sim.nlf)
#
#!! use netgen directly because xflow 8.1 goes mad when -tsim used a 2nd time
#!! see blog_xilinx_webpack.txt 2007-06-10
#
%_tsim.vhd %_tsim.sdf: %.ncd
	if [ ! -d ./ise ]; then mkdir ./ise; fi
	if [ -r $*.ncd ]; then cp -p $*.ncd ./ise; fi
	if [ -r $*.pcf ]; then cp -p $*.pcf ./ise; fi
	(cd ise; netgen -ofmt vhdl -sim -w -intstyle xflow -pcf \
	$*.pcf $*.ncd $*_tsim.vhd )
	(cd ./ise; chmod -x *.* )
	if [ -r ./ise/$*_tsim.vhd ]; then cp -p ./ise/$*_tsim.vhd .; fi
	if [ -r ./ise/$*_tsim.sdf ]; then cp -p ./ise/$*_tsim.sdf .; fi
	if [ -r ./ise/$*_tsim.nlf ]; then cp -p ./ise/$*_tsim.nlf ./$*_ngn_tsim.log; fi
	if [ -r $*_tsim.vhd -a -r $*.tsim_xon_dat ]; then xilinx_tsim_xon $*; fi
#
# generate dep_xst files from vbom
#
%.dep_xst: %.vbom
	vbomconv --dep_xst $< > $@
#
# generate cpp'ed ucf files from ucf_cpp
#
%.ucf : %.ucf_cpp
	cpp -I${RETROBASE}/rtl $*.ucf_cpp $*.ucf
#
# generate nested dependency rules for cpp'ed ucf files from ucf_cpp
#
%.dep_ucf_cpp : %.ucf_cpp
	cpp -I${RETROBASE}/rtl -MM $*.ucf_cpp |\
            sed 's/\.o:/\.ucf:/' > $*.dep_ucf_cpp
#
.PHONY : ise_clean ise_tmp_clean
#
ise_clean: ise_tmp_clean
	rm -rf *.ngc
	rm -rf *.ncd
	rm -rf *.pcf
	rm -rf *.bit
	rm -rf *.msk
	rm -rf *.svf
	rm -rf *_[sft]sim.vhd
	rm -rf *_tsim.sdf
	rm -rf *_xst.log
	rm -rf *_tra.log
	rm -rf *_map.log
	rm -rf *_par.log
	rm -rf *_pad.log
	rm -rf *_twr.log
	rm -rf *_bgn.log
	rm -rf *_ngn_[sft]sim.log
	rm -rf *_svn.log
	rm -rf *_sum.log
#
ise_tmp_clean:
	rm -rf ./ise
#
