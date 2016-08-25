org 0x7E00  ; kernel goes immediatly after bootloader
bits 16     ; 16 bit code (real mode)
%define SEGMENT_START 0x7E00
%define INT_SEGMENT 0x07E0

%define segoffset(num) num - SEGMENT_START

jmp kernel_early

; int 21h handler
int_21h_handler:
    cmp al, 00h ; print string stored in si
    je .print_string
    iret

.print_string:
    push si
    call print_string
    pop si
    iret

kernel_early: ; this gets executed first
    ; setup IVT
    ; segments are already zeroed (thanks to the bootloader)
    push ax
    push bx
    push es

    ; int 21h
    mov ax, 0
    mov es, ax
    mov bx, 132 ; 21h * 4
    mov word [es:bx], segoffset(int_21h_handler)
    add bx, 2
    mov word [es:bx], INT_SEGMENT

    ; cleanup
    pop es
    pop bx
    pop ax

    mov si, welcome ; print welcome message
    call print_string

    mov si, copyright ; print copyright message
    call print_string

    mov si, howto_help ; print instructions
    call print_string
    jmp kernel_main ; jump to main function

kernel_main:
    ; main `function'
    mov si, prompt ; print prompt
    call print_string

    mov di, buffer
    call read_input ; fetch and read user read_input

    mov si, buffer
    cmp byte [si], 00h ; we got an empty line?
    je kernel_main ; yep, looping again

    mov si, buffer
    mov di, str_hello ; "hi" command
    call strcmp ; compare those strings
    jc cmd_hello ; run it

    mov si, buffer
    mov di, str_help ; "help" command
    call strcmp
    jc cmd_help

    mov si, buffer
    mov di, str_hex
    call strcmp
    jc cmd_hex

    mov si, unknown_command ; unknown command entered
    call print_string

    jmp kernel_main ; loop

print_string:
    ; print a string until 0x00 is found (C-style)
    push ax ; push registers
    push bx
    push si

    mov ah, 0Eh
    mov bh, 00h
    ; we assume string location is stored in si
.loop_start:
    lodsb ; load byte at memory location si and advance
    
    cmp al, 00h ; if character is 00h return
    je .loop_end
    
    int 10h ; otherwise print it

    jmp .loop_start ; loop

.loop_end:
    pop si
    pop bx ; pop used registers
    pop ax
    ret ; return

print_hex:
    ; print a hexadecimal number stored in al
    ; this may not be the MOST efficient way,
    ; but it is made by me and not copied
    ; from teh Net
    push si
    push ax

    mov [.nybble], al
    and al, 0xF0 ; get higher nybble
    shr al, 4 ; remove lower nybble
    
    mov si, .continue_1
    cmp al, 0xA ; compare to 0xA (first non-digit item of hex)
    jl .adjust_0_to_9
    jge .adjust_A_to_F

.continue_1:
    mov ah, 0Eh
    int 10h

    mov al, [.nybble]
    and al, 0xF ; get lower nybble

    mov si, .continue_2
    cmp al, 0xA ; compare to 0xA (first non-digit item of hex)
    jl .adjust_0_to_9
    jge .adjust_A_to_F

.continue_2:
    mov ah, 0Eh
    int 10h ; print it

    pop ax
    pop si
    ret

.adjust_0_to_9:
    ; add 48
    add al, 48
    jmp si

.adjust_A_to_F:
    ; add 55
    add al, 55
    jmp si

.nybble: db 0


read_input: ; read user input
    push ax ; push registers
    push cx

    mov cl, 0h
.loop_start:
    mov ah, 00h
    int 16h ; wait for a key press. now al contains ASCII char

    mov ah, 0Eh
    cmp al, 13 ; check if return was pressed
    je .loop_end ; yep

    cmp al, 8 ; backspace?
    je .backspace

    ; otherwise store it in memory
    cmp cl, 63
    jge .loop_start ; 63 chars entered already - that's max!
    
    inc cl

    mov [di], al
    inc di ; advance

    int 10h ; print it
    jmp .loop_start

.backspace:
    ; erase a character
    cmp cl, 0 ; empty line?
    je .loop_start ; yep, ignore

    dec cl
    int 10h ; go one char left
    
    mov al, ' '
    int 10h ; print space (erase char standing there)

    mov al, 8
    int 10h ; move left again

    jmp .loop_start

.loop_end:
    mov byte [di], 00h ; string end

    ; print newline
    mov al, 0Dh
    int 10h
    mov al, 0Ah
    int 10h

    pop cx ; pop them back
    pop ax
    ret

strcmp: ; compare two strings stored in di and si
    push ax
.loop_start:
    mov al, [di]
    mov ah, [si]
    cmp ah, al
    jne .not_equal ; nope

    cmp al, 0h ; The End?
    je .equal ; The End

    inc si ; advance
    inc di

    jmp .loop_start

.equal:
    stc ; set carry flag
    pop ax ; pop ax back
    ret

.not_equal:
    clc ; clear carry flag
    pop ax ; pop ax back
    ret


cmd_hello: ; print hello world
    mov si, text_hello
    call print_string
    jmp kernel_main

cmd_help: ; print help message
    mov si, text_help
    push ax
    mov al, 00h
    int 21h ; print string

    pop ax
    jmp kernel_main

cmd_hex: ; print a hex number
    push ax

    mov ax, 0xA79E ; the hex number to print
    mov [.temp], al
    mov al, ah
    call print_hex
    mov al, [.temp]
    call print_hex

    pop ax
    jmp kernel_main
.temp: db 0


; data section
buffer: times 64 db 0 ; input buffer

welcome: ; welcome message
    db "WEEVIL-16", 0Dh, 0Ah, 0h
copyright: ; copyright message
    db "Copyright (C) Victor Kindhart 2015-2016", 0Dh, 0Ah, 0h
howto_help: ; brief help
    db "Enter help for information about the "
    db "system and its commands.", 0Dh, 0Ah, 0Dh, 0Ah, 0h
prompt: db "> ", 0h

str_hello: db "hello", 0h
str_help: db "help", 0h
str_hex: db "hex", 0h
unknown_command: db "Invalid command entered", 0Dh, 0Ah, 0h
text_hello: db "Hello world!", 0Dh, 0Ah, 0h
text_help: db "Commands: hello, help.", 0Dh, 0Ah, 0h
