; Music Demo
; Copyright (C) 2009 Julian Salazar (user Zenith)
; Entry for the Third 512-byte OS Contest at osdev.org
;
; You're free to use, redistribute, modify, and edit this program
; in any way as long you attribute the original to me.

org 0x7C00
use16

%define PITFREQ 1193180
%define G4 PITFREQ/392
%define A4 PITFREQ/440
%define B4 PITFREQ/494
%define C5 PITFREQ/523
%define D5 PITFREQ/587
%define E5 PITFREQ/659
%define F5 PITFREQ/698
%define G5 PITFREQ/784

start:

setup:
	; Setup the segment values
	xor ax, ax
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov sp, 0x7C00
	
init:
	; Set initial values
	mov di, clockticks ; Zero out clockticks
	stosd
	
	; Setup the video mode, clearing the screen
screen:
	; Set the value of ES
	mov ax, 0xB800
	mov es, ax
	; Set video-mode
	mov ax, 3
	int 0x10
	; Hide cursor
	inc ah
	mov cx, 0x2000 ; Not sure if cx is zeroed - could use mov ch, 0x20 instead
	int 0x10
	
	; Set up speaker to connect to timer 2
	mov al, 0xB6
	out 0x43, al
	
	mov word [msg], intromsg
	
play:
	mov si, intro
	xor edi, edi ; Initialize clock ticks
	jmp delay
	
; BX = Note frequency
; BP = Duration of note
playnote:
; AL = Note
; Bottom 4 bits = note
; If 4th bit set, do color flash
; Top 4 bits = duration
	movzx edi, al
	and al, 0x0F	; AL = Note
	and di, 0xF0	; DI = Duration
	
	shl al, 1		; multiply AL by 2
	shr di, 3		; Shift DI right by 3 (Number of ticks * 2)

	push edi
	movzx bp, al
	mov bx, [notes + bp]

	mov al, bl
	out 0x42, al
	mov al, bh
	out 0x42, al
	
	in al, 0x61
	or al, 3
	out 0x61, al
	
colorcolumn:
	; Clear the entire screen
	xor di, di
	mov cx, (160*25)/2
	mov ax, 0x0F20
	rep stosw
	
	; There are eight "color columns", 10 characters wide each
	; BP contains original note * 2
	mov ax, bp
	mov bl, 10
	mul bl
	mov di, ax
	mov ax, bp
	shl ax, 11	; Move to AH, divide by 2
	add ah, 0x20
	mov al, 0x20
	mov cx, 25
.loop:
	pusha
	mov cx, 10
	rep stosw
	popa
	add di, 160
	loop .loop
	
	pusha
	
	mov si, message
	mov di, (160*12)+29*2
	call print ; Reprint the message
	
	mov word si, [msg]
	mov di, (160*15)-6
	lodsb
	xor ah, ah
	add di, ax
	
	push si
	mov si, notechar
	call print
	pop si
	call print
	mov si, notechar
	call print
	
	popa
	
	pop edi
	
delay:
	xor eax, eax
	int 0x1A
	mov ax, cx
	shl eax, 16
	mov ax, dx
	
	mov ebx, eax
	sub eax, [clockticks]
	
	cmp eax, edi ; Delay of EDI clock ticks (18.2 ticks per second)
	jl delay
	
	mov [clockticks], ebx
	
loadnote:
	lodsb
	or al, al
	jnz playnote
	
	mov [msg], si
	lodsb
	or al, al
	jz .done
	call print
	jmp loadnote
	
.done:
	mov si, main
	jmp loadnote

; color byte is already set
; di is the offset in video memory to write to
print:
	; Print the message in the center of the screen
.loop:
	lodsb
	or al, al
	jz .done
	stosb
	or byte [es:di], 0x0F
	inc di
	jmp .loop
.done:
	ret
	
; G shall be the base note (0)
	
message:
	db "You Got Rickroll'd",0
notechar:
	db " ",14," ",0
intromsg:
	db 34*2,"(Intro)",0

notes:
	dw G4, A4, B4, C5, D5, E5, F5, G5

intro:
	db 0x83, 0x84, 0x60, 0x84, 0x85, 0x17, 0x16, 0x15, 0x14, 0x83, 0x84, 0x60, 0x35, 0x37, 0x85
main:
	; We're no strangers to love
	db 0,25*2,"We're no strangers to love",0
	db 0x31, 0x32, 0x33, 0x33, 0x34, 0x62, 0x61, 0xF0
	db 0,31*2,"...(Verse)...",0
	; You know the rules, and so do I
	db 0x31, 0x31, 0x32, 0x93, 0x30, 0x67, 0x37, 0xF4
	; A full commitment's what I'm thinking of
	db 0x31, 0x31, 0x32, 0x33, 0x31, 0x33, 0x64, 0x32, 0x31, 0xF0
	; You wouldn't get this from any another guy
	db 0x31, 0x31, 0x32, 0x33, 0x31, 0x60, 0x34, 0x34, 0x34, 0x35, 0xF4
	; I just want to tell you how I'm feeling
	db 0xE3, 0x34, 0x35, 0x33, 0x34, 0x34, 0x34, 0x35, 0x64, 0xF0
	; Gotta make you understand
	db 0x31, 0x32, 0x33, 0x61, 0x34, 0x35, 0x94
	db 0,26*2,"Never gonna give you up",0
	db 0x10, 0x11, 0x13, 0x11, 0x45, 0x45, 0x94
	db 0,31*2,"...(Chorus)...",0
	;db 0,29*2,"Never gonna let you down",0
	db 0x10, 0x11, 0x13, 0x11, 0x44, 0x44, 0x93
	;db 0,29*2,"Never gonna run around and desert you",0
	db 0x10, 0x11, 0x13, 0x11, 0x63, 0x34, 0x62, 0x60, 0x30, 0x64, 0xC3
	;db 0,29*2,"Never gonna make you cry",0 ; (same as never gonna give you up)
	db 0x10, 0x11, 0x13, 0x11, 0x65, 0x35, 0x94
	;db 0,29*2,"Never gonna say goodbye",0
	db 0x10, 0x11, 0x13, 0x11, 0x67, 0x32, 0x93
	;db 0,29*2,"Never gonna tell a lie and hurt you",0
	db 0x10, 0x11, 0x13, 0x11, 0x63, 0x34, 0xC2, 0x31, 0x30, 0x64, 0xF3
	db 0,0
	
times 510-($-$$) db 0
dw 0xAA55 ; Bootloader signature

;times 1474048 db 0

section .bss
clockticks: resd 1
msg: resd 1