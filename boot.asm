BITS 16
ORG 0x7C00
INBUF equ 0x7E00

start:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    cld
    mov ax, 0x0003
    int 0x10

shell:
    mov si, s_prompt
    call puts
    mov di, INBUF
    call gets
    cmp byte [INBUF], 0
    je shell

    mov di, c_cls
    call cmdcmp
    jz cmd_cls

    mov di, c_reboot
    call cmdcmp
    jz cmd_reboot

    mov di, c_halt
    call cmdcmp
    jz cmd_halt

    mov di, c_echo
    call cmdcmp
    jz cmd_echo

    mov di, c_color
    call cmdcmp
    jz cmd_color

    mov di, c_shell
    call cmdcmp
    jz shell

    mov si, s_unknown
    call puts
    jmp shell

cmd_cls:
    mov ah, 0x06        ; scroll/clear with current attribute
    xor al, al
    mov bh, [cur_attr]
    xor cx, cx
    mov dx, 0x184F      ; 25 rows, 80 cols
    int 0x10
    mov ah, 0x02        ; move cursor to 0,0
    xor bh, bh
    xor dx, dx
    int 0x10
    jmp shell

cmd_reboot:
    db 0xEA
    dw 0x0000
    dw 0xFFFF

cmd_halt:
    cli
.loop:
    hlt
    jmp .loop

cmd_echo:
    mov si, INBUF
.skip:
    lodsb
    cmp al, ' '
    je .print
    or al, al
    jnz .skip
    dec si
.print:
    call puts
    mov si, s_crlf
    call puts
    jmp shell

cmd_color:
    mov si, INBUF+6         ; skip "color "
    call hex_nibble
    jc .bad
    shl al, 4               ; background in high nibble
    mov bl, al
    call hex_nibble
    jc .bad
    or al, bl               ; combine bg+fg
    mov [cur_attr], al
    ; clear screen with new color
    mov ah, 0x06
    xor al, al
    mov bh, [cur_attr]
    xor cx, cx
    mov dx, 0x184F
    int 0x10
    mov ah, 0x02
    xor bh, bh
    xor dx, dx
    int 0x10
    jmp shell
.bad:
    mov si, s_cmdunknown
    call puts
    jmp shell

; -----------------------------------------------
; hex_nibble: parse one hex char from [SI]
;             returns value in AL, CF=1 on error
; -----------------------------------------------
hex_nibble:
    lodsb
    sub al, '0'
    jb .err
    cmp al, 9
    jbe .ok
    and al, 0xDF            ; force uppercase
    sub al, 7               ; A=10, B=11 ... F=15
    cmp al, 10
    jb .err
    cmp al, 15
    ja .err
.ok:
    clc
    ret
.err:
    stc
    ret

; -----------------------------------------------
; putchar: print AL with cur_attr, advance cursor
;          handles CR (13) and LF (10)
; -----------------------------------------------
putchar:
    push ax
    mov ah, 0x03
    xor bh, bh
    int 0x10
    pop ax
    cmp al, 13
    je .cr
    cmp al, 10
    je .lf
    cmp al, 8           ; <- add this
    je .bs              ; <- add this
    push dx
    mov ah, 0x09
    mov bl, [cur_attr]
    xor bh, bh
    mov cx, 1
    int 0x10
    pop dx
    inc dl
    jmp .set
.bs:
    test dl, dl         ; already at column 0?
    jz .set             ; if so do nothing
    dec dl              ; move cursor left
    jmp .set
.cr:
    xor dl, dl
    jmp .set
.lf:
    inc dh
    cmp dh, 25
    jb .set
    push dx             ; save cursor (dl = current column)
    mov ah, 0x06
    mov al, 1
    mov bh, [cur_attr]
    xor cx, cx
    mov dx, 0x184F      ; this trashes DX!
    int 0x10
    pop dx              ; restore original dl
    mov dh, 24
    jmp .set
.set:
    mov ah, 0x02
    xor bh, bh
    int 0x10
    ret

; -----------------------------------------------
; puts: print null-terminated string at SI
; -----------------------------------------------
puts:
    lodsb
    or al, al
    jz .done
    call putchar
    jmp puts
.done:
    ret

; -----------------------------------------------
; gets: read line into [DI], null-terminated
; -----------------------------------------------
gets:
    mov ah, 0x03
    xor bh, bh
    int 0x10
    mov bp, dx

    xor cx, cx
.r:
    xor ah, ah
    int 0x16
    cmp al, 13
    je .e
    cmp al, 8
    je .bs
    cmp cx, 62
    jae .r
    stosb
    inc cx
    push cx             ; save count
    call putchar
    pop cx              ; restore count
    jmp .r
.bs:
    test cx, cx
    jz .r
    push cx             ; save BEFORE int 0x10 trashes it
    mov ah, 0x03
    xor bh, bh
    int 0x10            ; CX = cursor shape here (clobbers count!)
    pop cx              ; restore count
    cmp dx, bp
    je .r
    dec di
    dec cx
    push cx
    mov al, 8
    call putchar
    mov al, ' '
    call putchar
    mov al, 8
    call putchar
    pop cx
    jmp .r
.e:
    mov byte [di], 0
    mov si, s_crlf
    push cx
    call puts
    pop cx
    ret

; -----------------------------------------------
; cmdcmp: ZF=1 if INBUF starts with [DI] + space/null
; -----------------------------------------------
cmdcmp:
    mov si, INBUF
.lp:
    mov al, [di]
    or al, al
    jz .check
    cmp al, [si]
    jne .ne
    inc si
    inc di
    jmp .lp
.check:
    mov al, [si]
    or al, al
    jz .match
    cmp al, ' '
    je .match
.ne:
    or ax, 1
    ret
.match:
    xor ax, ax
    ret

; -----------------------------------------------
; data
; -----------------------------------------------
cur_attr   db 0x07          ; default: light gray on black

s_prompt   db "$ ", 0
s_crlf     db 13, 10, 0
s_unknown  db "Err: IU", 13, 10, 0
s_cmdunknown  db "Err: IA", 13, 10, 0

c_cls      db "cls", 0
c_reboot   db "reboot", 0
c_halt     db "halt", 0
c_echo     db "echo", 0
c_color    db "color", 0
c_shell     db "sh", 0

times 510 - ($ - $$) db 0
dw 0xAA55