.setcpu "45GS02"

ZP = $12
ABS = $1234

   brk
   ora ($05,x)
   cle
   see
   tsb $02
   ora $02
   asl $02
   rmb0 $02
   php
   ora #$01
   asl
   tsy
   tsb $1234
   ora $1234
   asl $1234
   bbr0 $02, L0
L0:
   bpl L0
   ora ($06),y
   ora ($07),z
   lbpl *+$3133 ; bpl *+$3133
   trb $02
   ora $03,x
   asl $03,x
   rmb1 $02
   clc
   ora $1456,y
   inc
   inz
   trb $1234
   ora $1345,x
   asl $1345,x
   bbr1 $02,L1
L1:
   jsr $1234
   and ($05,x)
   jsr ($2345)
   jsr ($2456,x)
   bit $02
   and $02
   rol $02
   rmb2 $02
   plp
   and #$01
   rol
   tys
   bit $1234
   and $1234
   rol $1234
   bbr2 $02,L2
L2:
   bmi L2
   and ($06),y
   and ($07),z
   lbmi *+$3133 ; bmi *+$3133
   bit $03,x
   and $03,x
   rol $03,x
   rmb3 $02
   sec
   and $1456,y
   dec
   dez
   bit $1345,x
   and $1345,x
   rol $1345,x
   bbr3 $02,L3
L3:
   rti
   eor ($05,x)
   neg
   asr
   asr $02
   eor $02
   lsr $02
   rmb4 $02
   pha
   eor #$01
   lsr
   taz
   jmp $1234
   eor $1234
   lsr $1234
   bbr4 $02,L4
L4:
   bvc L4
   eor ($06),y
   eor ($07),z
   lbvc *+$3133 ; bvc *+$3133
   asr $03,x
   eor $03,x
   lsr $03,x
   rmb5 $02
   cli
   eor $1456,y
   phy
   tab
   map
   eor $1345,x
   lsr $1345,x
   bbr5 $02,L5
L5:
   rts
   adc ($05,x)
   rtn #$09
   bsr *+$3133
   stz $02
   adc $02
   ror $02
   rmb6 $02
   pla
   adc #$01
   ror
   tza
   jmp ($2345)
   adc $1234
   ror $1234
   bbr6 $02,L6
L6:
   bvs L6
   adc ($06),y
   adc ($07),z
   lbvs *+$3133 ; bvs *+$3133
   stz $03,x
   adc $03,x
   ror $03,x
   rmb7 $02
   sei
   adc $1456,y
   ply
   tba
   jmp ($2456,x)
   adc $1345,x
   ror $1345,x
   bbr7 $02,L7
L7:
   bra L7
   sta ($05,x)
   sta ($0f,s),y
   sta ($0f,sp),y
   lbra *+$3133 ; bra *+$3133
   sty $02
   sta $02
   stx $02
   smb0 $02
   dey
   bit #$01
   txa
   sty $1345,x
   sty $1234
   sta $1234
   stx $1234
   bbs0 $02,L8
L8:
   bcc L8
   sta ($06),y
   sta ($07),z
   lbcc *+$3133 ; bcc *+$3133
   sty $03,x
   sta $03,x
   stx $04,y
   smb1 $02
   tya
   sta $1456,y
   txs
   stx $1456,y
   stz $1234
   sta $1345,x
   stz $1345,x
   bbs1 $02,L9
L9:
   ldy #$01
   lda ($05,x)
   ldx #$01
   ldz #$01
   ldy $02
   lda $02
   ldx $02
   smb2 $02
   tay
   lda #$01
   tax
   ldz $1234
   ldy $1234
   lda $1234
   ldx $1234
   bbs2 $02,L10
L10:
   bcs L10
   lda ($06),y
   lda ($07),z
   lbcs *+$3133 ; bcs *+$3133
   ldy $03,x
   lda $03,x
   ldx $04,y
   smb3 $02
   clv
   lda $1456,y
   tsx
   ldz $1345,x
   ldy $1345,x
   lda $1345,x
   ldx $1456,y
   bbs3 $02,L11
L11:
   cpy #$01
   cmp ($05,x)
   cpz #$01
   dew $02
   cpy $02
   cmp $02
   dec $02
   smb4 $02
   iny
   cmp #$01
   dex
   asw $1234
   cpy $1234
   cmp $1234
   dec $1234
   bbs4 $02,L12
L12:
   bne L12
   cmp ($06),y
   cmp ($07),z
   lbne *+$3133 ; bne *+$3133
   cpz $02
   cmp $03,x
   dec $03,x
   smb5 $02
   cld
   cmp $1456,y
   phx
   phz
   cpz $1234
   cmp $1345,x
   dec $1345,x
   bbs5 $02,L13
L13:
   cpx #$01
   sbc ($05,x)
   lda ($0f,s),y
   lda ($0f,sp),y
   inw $02
   cpx $02
   sbc $02
   inc $02
   smb6 $02
   inx
   sbc #$01
   eom
   nop
   row $1234
   cpx $1234
   sbc $1234
   inc $1234
   bbs6 $02,L14
L14:
   beq L14
   sbc ($06),y
   sbc ($07),z
   lbeq *+$3133 ; beq *+$3133
   phd #$089a
   phw #$089a
   sbc $03,x
   inc $03,x
   smb7 $02
   sed
   sbc $1456,y
   plx
   plz
   phd $1234
   phw $1234
   sbc $1345,x
   inc $1345,x
   bbs7 $02,L15
L15:

   adc [$12],z

   adcq $12
   adcq $3456
   adcq ($78)
   adcq [$9a]

   and [$12],z

   andq $12
   andq $3456
   andq ($78)
   andq [$9a]

   aslq $12
   aslq
   aslq $3456
   aslq $78,x
   aslq $9abc,x

   asrq
   asrq $12
   asrq $34,x

   bitq $12
   bitq $3456

   cmp [$12],z

   cmpq $12
   cmpq $3456
   cmpq ($78)
   cmpq [$9a]

   deq
   deq $12
   deq $3456
   deq $78,x
   deq $9abc,x

   eor [$12],z

   eorq $12
   eorq $3456
   eorq ($78)
   eorq [$9a]

   inq
   inq $12
   inq $3456
   inq $78,x
   inq $9abc,x

   lda [$12],z

   ldq $12
   ldq $3456
   ldq ($78),z
   ldq [$9a],z

   lsrq $12
   lsrq
   lsrq $3456
   lsrq $78,x
   lsrq $9abc,x

   ora [$12],z

   orq $12
   orq $3456
   orq ($78)
   orq [$9a]

   rolq $12
   rolq
   rolq $3456
   rolq $78,x
   rolq $9abc,x

   rorq $12
   rorq
   rorq $3456
   rorq $78,x
   rorq $9abc,x

   sbc [$12],z

   sbcq $12
   sbcq $3456
   sbcq ($78)
   sbcq [$9a]

   sta [$12],z      ; EA 92 12

   stq $12
   stq $3456
   stq ($78)
   stq [$9a]
