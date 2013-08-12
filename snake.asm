; Snake512
; Copyright (C) 2009 Julian Salazar (user Zenith)
; Entry for the Second 512-byte OS Contest at osdev.org
;
; You're free to use, redistribute, modify, and edit this program
; in any way as long you attribute the original to me.

org 0x7C00
use16

start:

setup:
	; Setup the segment values
	xor eax, eax
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov sp, 0x7C00
	
init:
	; Set initial values
	mov di, clockticks ; Zero out clockticks and score
	stosd
	stosd
	; Initialize the snake pointer array
	mov ax, (160*25)/2 ; The first entry is the head of the snake
	stosw
	add al, 4
	stosw
	add al, 4
	stosw
	; Reset the keyboard
	mov al, 0xFF
	out 0x60, al
	; Turn off the PC speaker and get rid of those annoying beeps
	in al, 0x61
	and al, 0xFC
	out 0x61, al
	
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
	; Set screen color (yellow on black)
	xor di, di
	mov cx, (160*25)/2
	mov ax, 0x0E20
	pusha ; pusha takes less bytes than just saving one register
	rep stosw
	
.messages:
	mov di, (160*3)+42
	mov si, msg_name ; Print message (using di as the position)
	call print
	mov si, msg_score
	mov di, (160*3)+94
	call print
	mov si, msg_controls
	mov di, (160*21)+42
	call print
	
.rect:
	; Draw rectangle around playable area
	mov ax, 0x02FE
	mov cx, 38
	mov di, (160*4)+40
	rep stosw
	mov cx, 16
.rect_loop:
	stosw
	pusha
	mov cx, 41
	xor ah, ah
	rep stosw
	mov ah, 2
	stosw
	popa
	add di, 158
	loop .rect_loop
	mov cx, 38
	mov di, (160*20)+42
	rep stosw

; New Game!
game:

.setup:
	popa ; Restore values
	
	; Draw initial snake at the center of the map (the snake buffer is pre-initialized)
	mov di, cx
	mov si, init_snake
	call print
	mov bp, 6 ; This is the length of the snake * 2
	call place_food
	
.delay:
	xor eax, eax
	int 0x1A
	mov ax, cx
	shl eax, 16
	mov ax, dx
	
	mov ebx, eax
	sub eax, [clockticks]
	
	cmp eax, 3 ; Delay of 3 clock ticks (18.2 ticks per second)
	jl .delay

	mov [clockticks], ebx
	
	; get the last scan code (will return previous if no new key)
	in al, 0x60
	
	; scan codes
	; up = 83, left = 79, down = 84, right = 89 (not working)
	; w = 17, a = 30, s = 31, d = 32
.direction:
	cmp al, 177 ; 'n' - new game, only when 'n' is released
	je start
	and al, 0x7F ; Recognize both press and release codes
	cmp al, 17 ; 'w' - up
	je .up
	cmp al, 30 ; 'a' - left
	je .left
	cmp al, 31 ; 's' - down
	je .down
	cmp al, 32 ; 'd' - right
	jne .delay

.right:
	mov al, '>'
	add di, 4
	jmp .move
	
.up:
	mov al, '^'
	sub di, 160
	jmp .move

.down:
	mov al, 'v'
	add di, 160
	jmp .move
	
.left:
	mov al, '<'
	sub di, 4
	
.move:	
	; Check if eating
	cmp byte [es:di], 'o'
	sete ah
	je .nofail
	cmp byte [es:di], ' ' ; If it hits the wall or itself
	jne .fail
	
.nofail:
	; Move the head
	stosb
	dec di
	
	pusha ; Save di
	
	; Copy snake buffer backward once (move the pointers over)
	push es ; Save current value of es
	push ds ; Set es to 0
	pop es
	mov cx, bp
	inc cx
	mov si, snake
	add si, bp ; si points to last array entry
	mov di, si
	inc di
	inc di ; di points to next cell
	std ; set direction flag (the 'good' kind of std)
	rep movsb
	cld
	pop es
	
	popa ; Restore/save di again
	push di
	mov [snake], di ; Save pointer to the new head of the snake
	mov di, [snake+2]
	mov al, '*'
	stosb ; Replace old head with body
	
	; Did the snake eat the food?
	cmp ah, 1
	je .food
	
	; Food wasn't eaten, clear the end of the snake	
	mov di, [snake+bp]
	mov al, ' '
	stosb
	
	jmp .done
	
.food:
	inc bp
	inc bp ; Increase snake length in bp
	
	mov di, (160*3)+114
	add word [score], 4
	mov ax, [score]
	mov bl, 10
.printscore_loop:
	div bl
	xchg al, ah
	add al, '0'
	stosb
	dec di ; Apparently, this is shorter than sub di, 3
	dec di
	dec di
	mov al, ah
	xor ah, ah
	or al, al
	jnz .printscore_loop
	call place_food
.done:
	pop di ; Restore di
	jmp .delay

.fail:
	mov di, (160*19)+92
	mov si, msg_fail
	call print
.fail_wait: ; Wait for N to be released
	in al, 0x60
	cmp al, 177
	jne .fail_wait
	jmp start

place_food:
	pusha
	; Place the next piece of food
	; Uses a Park–Miller random number generator with n=65537 and g=75
	; The seed will be the lower word of the RTC (dx)
.seed:
	xor eax, eax
	xor bl, bl
	int 0x1A
.random:
	cmp bl, 5 ; If it's looped 5 times, current seed is probably hopeless, get new one
	jg .seed
	
	; Algorithm: Xn+1 = (Xn * 75) mod 65537 (these values were used in the ZX Spectrum)
	mov ax, dx
	mov cx, 75
	mul cx ; dx:ax = current_num * g
	movzx edx, dx
	mov ecx, 65537
	div ecx ; edx = edx:eax mod ecx = (seed * g) mod n = next number in sequence
	mov ax, dx
	shr edx, 16
	mov ecx, (160*20)
	div cx ; dx = dx:ax mod cx = offset to place next food at (puts number within range)
	and dl, 0xFC ; make value divisible by 4
	
	; Test if value is usable
	inc bl
	cmp dx, (160*5) ; Food can't be in the upper row, or else the snake won't reach it ;)
	jl .random
	mov di, dx
	cmp byte [es:di], 0x20 ; Check if the area is empty space
	jne .random
	
	mov al, 'o'
	stosb ; Draw the food
	popa
	ret
	
; color byte is already set
; di is the offset in video memory to write to
print:
	pusha
.loop:
	lodsb
	or al, al
	jz .done
	stosb
	inc di
	jmp .loop
.done:
	popa
	ret

msg_name: db 'Snake512',0
msg_controls: db 'WASD - Direction, N - New Game',0
msg_fail: db 'You lost =(',0
msg_score: db 'Score:',0
init_snake: db '< * *',0

times 510-($-$$) db 0
dw 0xAA55 ; Bootloader signature

section .bss
clockticks: resd 1
score: resd 1 ; Only the word is used, aligns snake to 4-bytes
snake: ; This is the base of an array of pointers
