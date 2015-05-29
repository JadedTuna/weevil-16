; WEEVIL-16 bootloader
org 0x7C00  ; BIOS generally loads bootloaders there
bits 16     ; 16 bit code (real mode)

mov ax, 0   ; set up es segment
mov es, ax

mov ss, ax     ; setup stack
mov sp, 0xFFFF ; stack grows downwards

jmp kernel_load

kernel_load:
    ; set video mode
    mov ah, 00h
    mov al, 03h
    int 10h ; 80x25, text mode, color
    call disk_reset

    jc .error_reset ; some error occured

    ; read kernel from floppy
    mov cx, 3
.try_read:
    push cx
    call disk_reset

    mov ah, 02h
    mov al, 10h ; 0x10 (16) * 512 = 8 KB
    mov ch, 00h ; first cylinder
    mov cl, 02h ; start from second sector (first is bootloader)
    mov dh, 00h ; first head
    mov dl, 00h ; floppy

    mov bx, kernel ; read into address of label kernel

    int 13h ; try to read

    jnc .done_read ; success

    pop cx
    loop .try_read

    jmp .error_read

.done_read:
    ; some more setup

    mov ax, 0   ; set up segments (again)
    mov ds, ax
    mov es, ax
    jmp kernel ; start executing it

.error_reset:
    mov si, str_error_reset
    call print_string
    cli
    hlt
    jmp $

.error_read:
    mov si, str_error_read
    call print_string
    cli
    hlt
    jmp $

disk_reset:
    ; reset disk system (move to the beginning)
    push ax
    push dx

    mov ah, 00h
    mov dl, 00h ; floppy
    int 13h

    pop dx
    pop ax
    ret

print_string:
.next:
    lodsb
    cmp al, 00h
    je  .f_end
    mov ah, 0Eh
    mov bh, 00h
    mov bl, 0fh
    int 10h
    jmp .next

.f_end:
    ret

; strings
str_error_reset: db "Failed to reset disk system.", 0Dh, 0Ah, 0h
str_error_read: db "Failed to read kernel from floppy.", 0Dh, 0Ah, 0h

times 510 - ($ - $$) db 0h
dw 0xAA55 ; Required by BIOS to correctly interpret the section
kernel: ; kernel goes here