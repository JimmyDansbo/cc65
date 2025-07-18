;
; Serial driver for the built-in 6551 ACIA of the Plus/4.
;
; Ullrich von Bassewitz, 2003-12-13
;
; The driver is based on the cc65 rs232 module, which in turn is based on
; Craig Bruce's device driver for the Switftlink/Turbo-232.
;
; SwiftLink/Turbo-232 v0.90 device driver, by Craig Bruce, 14-Apr-1998.
;
; This (C. Bruce) software is Public Domain.  It is in Buddy assembler format.
;
; This device driver uses the SwiftLink RS-232 Serial Cartridge, available from
; Creative Micro Designs, Inc, and also supports the extensions of the Turbo232
; Serial Cartridge.  Both devices are based on the 6551 ACIA chip.  It also
; supports the "hacked" SwiftLink with a 1.8432 MHz crystal.
;
; The code assumes that the kernal + I/O are in context.  On the C128, call
; it from Bank 15.  On the C64, don't flip out the Kernal unless a suitable
; NMI catcher is put into the RAM under the Kernal.  For the SuperCPU, the
; interrupt handling assumes that the 65816 is in 6502-emulation mode.
;

        .include        "zeropage.inc"
        .include        "ser-kernel.inc"
        .include        "ser-error.inc"
        .include        "plus4.inc"

        .macpack        module


; ------------------------------------------------------------------------
; Header. Includes jump table

        module_header   _plus4_stdser_ser

; Driver signature

        .byte   $73, $65, $72           ; ASCII "ser"
        .byte   SER_API_VERSION         ; Serial API version number

; Library reference

        .addr   $0000

; Jump table

        .word   SER_INSTALL
        .word   SER_UNINSTALL
        .word   SER_OPEN
        .word   SER_CLOSE
        .word   SER_GET
        .word   SER_PUT
        .word   SER_STATUS
        .word   SER_IOCTL
        .word   SER_IRQ

;----------------------------------------------------------------------------
; I/O definitions

ACIA            := $FD00
ACIA_DATA       := ACIA+0       ; Data register
ACIA_STATUS     := ACIA+1       ; Status register
ACIA_CMD        := ACIA+2       ; Command register
ACIA_CTRL       := ACIA+3       ; Control register

RecvHead        := $07D1        ; Head of receive buffer
RecvTail        := $07D2        ; Tail of receive buffer
RecvFreeCnt     := $07D3        ; Number of bytes in receive buffer
;----------------------------------------------------------------------------
;
; Global variables
;

.bss
SendHead:       .res    1       ; Head of send buffer
SendTail:       .res    1       ; Tail of send buffer
SendFreeCnt:    .res    1       ; Number of bytes in send buffer

Stopped:        .res    1       ; Flow-stopped flag
RtsOff:         .res    1       ;

; Send and receive buffers: 256 bytes each
RecvBuf:        .res    256
SendBuf:        .res    256

.rodata

; Tables used to translate RS232 params into register values

BaudTable:                      ; Bit7 = 1 means setting is invalid
        .byte   $FF             ; SER_BAUD_45_5
        .byte   $01             ; SER_BAUD_50
        .byte   $02             ; SER_BAUD_75
        .byte   $03             ; SER_BAUD_110
        .byte   $04             ; SER_BAUD_134_5
        .byte   $05             ; SER_BAUD_150
        .byte   $06             ; SER_BAUD_300
        .byte   $07             ; SER_BAUD_600
        .byte   $08             ; SER_BAUD_1200
        .byte   $09             ; SER_BAUD_1800
        .byte   $0A             ; SER_BAUD_2400
        .byte   $0B             ; SER_BAUD_3600
        .byte   $0C             ; SER_BAUD_4800
        .byte   $0D             ; SER_BAUD_7200
        .byte   $0E             ; SER_BAUD_9600
        .byte   $0F             ; SER_BAUD_19200
        .byte   $FF             ; SER_BAUD_38400
        .byte   $FF             ; SER_BAUD_57600
        .byte   $FF             ; SER_BAUD_115200
        .byte   $FF             ; SER_BAUD_230400

BitTable:
        .byte   $60             ; SER_BITS_5
        .byte   $40             ; SER_BITS_6
        .byte   $20             ; SER_BITS_7
        .byte   $00             ; SER_BITS_8

StopTable:
        .byte   $00             ; SER_STOP_1
        .byte   $80             ; SER_STOP_2

ParityTable:
        .byte   $00             ; SER_PAR_NONE
        .byte   $20             ; SER_PAR_ODD
        .byte   $60             ; SER_PAR_EVEN
        .byte   $A0             ; SER_PAR_MARK
        .byte   $E0             ; SER_PAR_SPACE

.code

;----------------------------------------------------------------------------
; SER_INSTALL routine. Is called after the driver is loaded into memory. If
; possible, check if the hardware is present.
; Must return an SER_ERR_xx code in a/x.
;
; Since we don't have to manage the IRQ vector on the Plus/4, this is actually
; the same as:
;
; SER_UNINSTALL routine. Is called before the driver is removed from memory.
; Must return an SER_ERR_xx code in a/x.
;
; and:
;
; SER_CLOSE: Close the port, disable interrupts and flush the buffer. Called
; without parameters. Must return an error code in a/x.
;

SER_INSTALL:
SER_UNINSTALL:
SER_CLOSE:

; Deactivate DTR and disable 6551 interrupts

        lda     #%00001010
        sta     ACIA_CMD

; Done, return an error code

        lda     #SER_ERR_OK
        .assert SER_ERR_OK = 0, error
        tax
        rts

;----------------------------------------------------------------------------
; PARAMS routine. A pointer to a ser_params structure is passed in ptr1.
; Must return an SER_ERR_xx code in a/x.

SER_OPEN:

; Check if the handshake setting is valid

        ldy     #SER_PARAMS::HANDSHAKE  ; Handshake
        lda     (ptr1),y
        cmp     #SER_HS_HW              ; This is all we support
        bne     InvParam

; Initialize buffers

        ldx     #0
        stx     Stopped
        stx     RecvHead
        stx     RecvTail
        stx     SendHead
        stx     SendTail
        dex                             ; X = 255
        stx     RecvFreeCnt
        stx     SendFreeCnt

; Set the value for the control register, which contains stop bits, word
; length and the baud rate.

        ldy     #SER_PARAMS::BAUDRATE
        lda     (ptr1),y                ; Baudrate index
        tay
        lda     BaudTable,y             ; Get 6551 value
        bmi     InvBaud                 ; Branch if rate not supported
        sta     tmp1

        ldy     #SER_PARAMS::DATABITS   ; Databits
        lda     (ptr1),y
        tay
        lda     BitTable,y
        ora     tmp1
        sta     tmp1

        ldy     #SER_PARAMS::STOPBITS   ; Stopbits
        lda     (ptr1),y
        tay
        lda     StopTable,y
        ora     tmp1
        ora     #%00010000              ; Receiver clock source = baudrate
        sta     ACIA_CTRL

; Set the value for the command register. We remember the base value in
; RtsOff, since we will have to manipulate ACIA_CMD often.

        ldy     #SER_PARAMS::PARITY     ; Parity
        lda     (ptr1),y
        tay
        lda     ParityTable,y
        ora     #%00000001              ; DTR active
        sta     RtsOff
        ora     #%00001000              ; Enable receive interrupts
        sta     ACIA_CMD

; Done

        lda     #SER_ERR_OK
        .assert SER_ERR_OK = 0, error
        tax
        rts

; Invalid parameter

InvParam:
        lda     #SER_ERR_INIT_FAILED
        ldx     #0 ; return value is char
        rts

; Baud rate not available

InvBaud:
        lda     #SER_ERR_BAUD_UNAVAIL
        ldx     #0 ; return value is char
        rts

;----------------------------------------------------------------------------
; SER_GET: Will fetch a character from the receive buffer and store it into the
; variable pointer to by ptr1. If no data is available, SER_ERR_NO_DATA is
; return.
;

SER_GET:

; Check for buffer empty

        lda     RecvFreeCnt             ; (25)
        cmp     #$ff
        bne     @L2
        lda     #SER_ERR_NO_DATA
        ldx     #0 ; return value is char
        rts

; Check for flow stopped & enough free: release flow control

@L2:    ldx     Stopped                 ; (34)
        beq     @L3
        cmp     #63
        bcc     @L3
        lda     #$00
        sta     Stopped
        lda     RtsOff
        ora     #%00001000
        sta     ACIA_CMD

; Get byte from buffer

@L3:    ldx     RecvHead                ; (41)
        lda     RecvBuf,x
        inc     RecvHead
        inc     RecvFreeCnt
        ldx     #$00                    ; (59)
        sta     (ptr1,x)
        txa                             ; Return code = 0
        rts

;----------------------------------------------------------------------------
; SER_PUT: Output character in A.
; Must return an error code in a/x.
;

SER_PUT:

; Try to send

        ldx     SendFreeCnt
        cpx     #$ff                   ; Nothing to flush
        beq     @L2
        pha
        lda     #$00
        jsr     TryToSend
        pla

; Reload SendFreeCnt after TryToSend

        ldx     SendFreeCnt
        bne     @L2
        lda     #SER_ERR_OVERFLOW      ; X is already zero
        rts

; Put byte into send buffer & send

@L2:    ldx     SendTail
        sta     SendBuf,x
        inc     SendTail
        dec     SendFreeCnt
        lda     #$ff
        jsr     TryToSend
        lda     #SER_ERR_OK
        .assert SER_ERR_OK = 0, error
        tax
        rts

;----------------------------------------------------------------------------
; SER_STATUS: Return the status in the variable pointed to by ptr1.
; Must return an error code in a/x.
;

SER_STATUS:
        lda     ACIA_STATUS
        ldx     #0
        sta     (ptr1,x)
        .assert SER_ERR_OK = 0, error
        txa
        rts

;----------------------------------------------------------------------------
; SER_IOCTL: Driver defined entry point. The wrapper will pass a pointer to ioctl
; specific data in ptr1, and the ioctl code in A.
; Must return an error code in a/x.
;

SER_IOCTL:
        lda     #SER_ERR_INV_IOCTL      ; We don't support ioclts for now
        ldx     #0 ; return value is char
        rts                             ; Run into IRQ instead

;----------------------------------------------------------------------------
; SER_IRQ: Called from the builtin runtime IRQ handler as a subroutine. All
; registers are already save, no parameters are passed, but the carry flag
; is clear on entry. The routine must return with carry set if the interrupt
; was handled, otherwise with carry clear.
;

SER_IRQ:
        lda     ACIA_STATUS     ; (4)  Check for byte received
        and     #$08            ; (2)
        beq     @L9             ; (2*)

        lda     ACIA_DATA       ; (4)  Get byte and put into receive buffer
        ldy     RecvTail        ; (4)
        ldx     RecvFreeCnt     ; (4)
        beq     @L3             ; (2*) Jump if no space in receive buffer
        sta     RecvBuf,y       ; (5)
        inc     RecvTail        ; (6)
        dec     RecvFreeCnt     ; (6)
        cpx     #33             ; (2)  Check for buffer space low
        bcc     @L2             ; (2*)
        rts                     ; Return with carry set (interrupt handled)

; Assert flow control if buffer space too low

@L2:    lda     RtsOff          ; (3)
        sta     ACIA_CMD        ; (4)
        sta     Stopped         ; (3)
@L3:    sec                     ; Interrupt handled
@L9:    rts

;----------------------------------------------------------------------------
; Try to send a byte. Internal routine. A = TryHard

.proc   TryToSend

        sta     tmp1            ; Remember tryHard flag
@L0:    lda     SendFreeCnt
        cmp     #$ff
        beq     @L2             ; Bail out

; Check for flow stopped

@L1:    lda     Stopped
        bne     @L2             ; Bail out

; Check that swiftlink is ready to send

        lda     ACIA_STATUS
        and     #$10
        bne     @L3
        bit     tmp1            ;keep trying if must try hard
        bmi     @L1
@L2:    rts

; Send byte and try again

@L3:    ldx     SendHead
        lda     SendBuf,x
        sta     ACIA_DATA
        inc     SendHead
        inc     SendFreeCnt
        jmp     @L0

.endproc
