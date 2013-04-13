# $Id: test_w11a_dstm_word_flow.tcl 502 2013-04-02 19:29:30Z mueller $
#
# Copyright 2013- by Walter F.J. Mueller <W.F.J.Mueller@gsi.de>
# License disclaimer see LICENSE_gpl_v2.txt in $RETROBASE directory
#
# Revision History:
# Date         Rev Version  Comment
# 2013-03-31   502   1.0    Initial version
#
# Test dstm flow with inc ... instructions for word access
#

rlc log "test_w11a_dstm_word_flow: test dstm flow for word with inc ..."
rlc log "  r0,(r0),(r0)+,@(r0)+,-(r0),@-(r0) (mode=0,1,2,3,4,5)"
$cpu ldasm -lst lst -sym sym {
        . = 1000
start:  inc     r0
        inc     (r1)
        inc     (r2)+
        inc     (r2)+
        inc     @(r3)+
        inc     @(r3)+
        inc     -(r4)
        inc     -(r4)
        inc     @-(r5)
        inc     @-(r5)
        halt
stop:
data1:  .word   20
data2:  .word   30,31
data3:  .word   40,41
data4:  .word   50,51
data4e:
data5:  .word   60,61
data5e:
pdata3: .word   data3,data3+2
pdata5: .word   data5,data5+2
pdat5e:
}

rw11a::asmrun  $cpu sym [list r0 010 \
                              r1 $sym(data1) \
                              r2 $sym(data2) \
                              r3 $sym(pdata3) \
                              r4 $sym(data4e) \
                              r5 $sym(pdat5e) ]
rw11a::asmwait $cpu sym 1.0
rw11a::asmtreg $cpu [list r0 011 \
                          r1 $sym(data1) \
                          r2 [expr {$sym(data2)  + 4}] \
                          r3 [expr {$sym(pdata3) + 4}] \
                          r4 [expr {$sym(data4e) - 4}] \
                          r5 [expr {$sym(pdat5e) - 4}] ]
rw11a::asmtmem $cpu $sym(data1) {021 031 032 041 042 051 052 061 062}


rlc log "  nn(r0),@nn(r0),var,@var,@#var (mode=6,7,67,77,37)"
$cpu ldasm -lst lst -sym sym {
        . = 1000
start:  inc     20(r0)
        inc     @40(r1)
        inc     data2
        inc     @pdata3
        inc     @#data4
        halt
stop:
data0:  .word   200
data1:  .word   210
data2:  .word   220
data3:  .word   230
data4:  .word   240
data4e:
pdata1: .word   data1
pdata3: .word   data3
}

rw11a::asmrun  $cpu sym [list r0 [expr {$sym(data0)-020}] \
                              r1 [expr {$sym(pdata1)-040}]  ]
rw11a::asmwait $cpu sym 1.0
rw11a::asmtmem $cpu $sym(data0) {0201 0211 0221 0231 0241}
