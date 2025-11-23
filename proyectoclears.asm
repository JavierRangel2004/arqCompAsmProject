org 100h

jmp start

; ========= DATOS =========
msgWelcome      db  13,10, "=== BANCO ENSAMBLADOR ===", 13,10, "$"
msgEnterPin     db  13,10, "Introduce tu PIN de 4 digitos: $"
msgPinError     db  13,10, "PIN incorrecto. Intenta de nuevo.", 13,10, "$"
msgBlocked      db  13,10, "Cuenta bloqueada. Demasiados intentos.", 13,10, "$"
msgLoginOk      db  13,10, "Acceso concedido.", 13,10, "$"
msgMenu         db  13,10, "----- MENU PRINCIPAL -----", 13,10
                db  "1) Consultar saldo", 13,10
                db  "2) Depositar", 13,10
                db  "3) Retirar", 13,10
                db  "4) Salir", 13,10
                db  "Selecciona una opcion: $"
msgSaldo        db  13,10, "Saldo actual: $"
msgDeposito     db  13,10, "Cantidad a depositar: $"
msgRetiro       db  13,10, "Cantidad a retirar: $"
msgNoFondos     db  13,10, "Error: fondos insuficientes.", 13,10, "$"
msgAdios        db  13,10, "Gracias por usar Banco Ensamblador.", 13,10, "$"
msgInvalido     db  13,10, "Entrada invalida.", 13,10, "$"
msgOk           db  13,10, "Operacion realizada correctamente.", 13,10, "$"
msgOverflow     db  13,10, "Error: cantidad excede el limite permitido.", 13,10, "$"
msgContinuar    db  13,10, "Presiona cualquier tecla para continuar...$"

CorrectPIN      db  "1234"      ; PIN correcto (4 bytes)
Balance         dw  1000        ; saldo inicial: 1000

; Buffer DOS para leer PIN (función 0Ah)
; Estructura: [0]=max, [1]=longitud real, [2..]=datos
pin_buffer      db  5           ; max 5 chars (4 + Enter)
pin_len         db  ?           ; longitud real introducida
pin_data        db  5 dup(?)    ; aquí se almacenan los caracteres

; Buffer para cantidades
num_buffer      db  6           ; max 6 chars (hasta 65535)
num_len         db  ?
num_data        db  6 dup(?)

; Buffer para imprimir números
out_buffer      db  6 dup('$')  ; hasta 5 dígitos + '$'

; Bandera para salir del menú
end_flag        db  0           ; 0 = seguir en menu, 1 = salir

crlf            db  13,10, "$"

; ========= CÓDIGO =========
start:
    ; Limpiar pantalla
    call limpiar
    
    ; Bienvenida
    mov dx, offset msgWelcome
    call PrintStr

    ; Login
    call LoginPIN
    jz  login_ok       ; ZF=1 => login exitoso
    
    ; si falla:
    mov dx, offset msgBlocked
    call PrintStr
    jmp exit_program 

login_ok:
    mov dx, offset msgLoginOk
    call PrintStr
    call PrintCRLF
    
    ; Esperar tecla antes de mostrar el menú
    mov ah, 00h
    int 16h
    call limpiar

menu_loop:
    cmp end_flag, 1
    je  exit_menu
    call MenuPrincipal
    jmp menu_loop
    
limpiar:
    mov ax, 3
    int 10h
    ret

exit_menu:
    mov dx, offset msgAdios
    call PrintStr

exit_program:
    mov ah, 4Ch
    mov al, 00h
    int 21h

; ---------- Subrutina: PrintStr ----------
; DX = offset de la cadena terminada en '$'
PrintStr proc
    mov ah, 09h
    int 21h
    ret
PrintStr endp

; ---------- Subrutina: PrintCRLF ----------
PrintCRLF proc
    mov dx, offset crlf
    mov ah, 09h
    int 21h
    ret
PrintCRLF endp

; ---------- Subrutina: ReadLine (usa buffer DOS 0Ah) ----------
; DX = offset del buffer estructurado
ReadLine proc
    mov ah, 0Ah
    int 21h
    ret
ReadLine endp

; ---------- Subrutina: LoginPIN ----------
; Retorna: ZF=1 si login exitoso, ZF=0 si falló
LoginPIN proc
    mov cx, 3          ; intentos

login_loop:
    mov dx, offset msgEnterPin
    call PrintStr
    mov dx, offset pin_buffer
    call ReadLine
    
    ; Leer longitud real desde pin_len
    mov al, pin_len
    cmp al, 4
    jne pin_fail
    
    ; comparar 4 caracteres con CorrectPIN
    mov si, offset pin_data
    mov di, offset CorrectPIN
    mov bx, 4

cmp_loop:
    mov al, [si]
    cmp al, [di]
    jne pin_fail
    inc si
    inc di
    dec bx
    jnz cmp_loop
    
    ; si llegamos aquí, PIN correcto
    ; ZF=1 para indicar éxito
    mov ax, 0
    cmp ax, 0          ; fuerza ZF=1 
    call limpiar
    ret

pin_fail:
    mov dx, offset msgPinError
    call PrintStr
    dec cx
    jz login_final_fail    ; si cx = 0, ya no hay más intentos
    call limpiar           ; limpiar antes del siguiente intento
    jmp login_loop

login_final_fail:
    ; fallaron los 3 intentos
    mov ax, 1
    cmp ax, 0          ; ZF=0
    ret
LoginPIN endp

; ---------- Subrutina: MenuPrincipal ----------
MenuPrincipal proc
    mov dx, offset msgMenu
    call PrintStr
    
    ; Leer una tecla
    mov ah, 01h
    int 21h            ; AL = tecla
    
    ; Tratar Enter como inválido
    cmp al, 13         ; Enter (carriage return)
    je opcion_invalida
    cmp al, 10         ; Line feed
    je opcion_invalida
    
    cmp al, '1'
    je opcion1
    cmp al, '2'
    je opcion2
    cmp al, '3'
    je opcion3
    cmp al, '4'
    je opcion4
    
opcion_invalida:
    mov dx, offset msgInvalido
    call PrintStr
    call PrintCRLF
    ret

opcion1:
    call ConsultarSaldo
    ret

opcion2:
    call Depositar
    ret

opcion3:
    call Retirar
    ret

opcion4:
    mov end_flag, 1
    ret

MenuPrincipal endp

; ---------- ConsultarSaldo ----------
ConsultarSaldo proc
    mov dx, offset msgSaldo
    call PrintStr
    
    mov ax, Balance
    mov di, offset out_buffer
    call IntToStr
    
    mov dx, offset out_buffer
    call PrintStr
    call PrintCRLF
    
    ; Esperar a que presione una tecla
    mov dx, offset msgContinuar
    call PrintStr
    mov ah, 00h
    int 16h
    
    call limpiar
    
    ret
ConsultarSaldo endp

; ---------- Depositar ----------
Depositar proc
    mov dx, offset msgDeposito
    call PrintStr
    
    mov dx, offset num_buffer
    call ReadLine
    call PrintCRLF
    
    mov cl, num_len
    cmp cl, 0
    je dep_error
    
    mov si, offset num_data
    call StrToInt
    jc  dep_error      ; CF=1 => error
    
    ; AX = cantidad a depositar
    ; Validar desbordamiento: Balance + AX no debe exceder 65535
    mov bx, Balance
    mov dx, 65535
    sub dx, bx         ; DX = espacio disponible
    cmp ax, dx
    ja dep_overflow    ; si cantidad > espacio disponible
    
    add Balance, ax
    
    mov dx, offset msgOk
    call PrintStr
    
    ; Esperar tecla
    mov ah, 00h
    int 16h
    
    call limpiar
    
    ret

dep_overflow:
    mov dx, offset msgOverflow
    call PrintStr
    mov ah, 00h
    int 16h
    call limpiar
    ret

dep_error:
    mov dx, offset msgInvalido
    call PrintStr
    mov ah, 00h
    int 16h
    call limpiar
    ret
Depositar endp

; ---------- Retirar ----------
Retirar proc
    mov dx, offset msgRetiro
    call PrintStr
    
    mov dx, offset num_buffer
    call ReadLine
    call PrintCRLF
    
    mov cl, num_len
    cmp cl, 0
    je ret_error
    
    mov si, offset num_data
    call StrToInt
    jc  ret_error
    
    ; AX = cantidad a retirar
    mov bx, Balance
    cmp ax, bx
    ja  no_fondos      ; si retiro > saldo
    
    sub Balance, ax
    
    mov dx, offset msgOk
    call PrintStr
    
    ; Esperar tecla
    mov ah, 00h
    int 16h
    
    call limpiar
    
    ret

no_fondos:
    mov dx, offset msgNoFondos
    call PrintStr
    mov ah, 00h
    int 16h
    call limpiar
    ret

ret_error:
    mov dx, offset msgInvalido
    call PrintStr
    mov ah, 00h
    int 16h
    call limpiar
    ret
Retirar endp

; ---------- StrToInt ----------
; SI = offset primer dígito, CL = longitud
; Retorna AX = valor, CF=1 si error / overflow
StrToInt proc
    push bx
    push dx
    push cx
    
    mov ax, 0
    cmp cl, 0
    je stoi_error

stoi_loop:
    mov bl, [si]
    cmp bl, '0'
    jb stoi_error
    cmp bl, '9'
    ja stoi_error
    
    sub bl, '0'        ; ahora BL = valor numérico (0-9)
    mov bh, 0          ; extender a 16 bits
    
    ; Validar desbordamiento antes de multiplicar (AX * 10)
    cmp ax, 6553
    ja stoi_error
    
    ; AX = AX * 10
    mov dx, ax
    shl ax, 1          ; AX = AX*2
    shl dx, 3          ; DX = AX*8 (copia)
    add ax, dx         ; AX = AX*10
    
    ; Validar desbordamiento antes de sumar
    mov dx, 65535
    sub dx, bx
    cmp ax, dx
    ja stoi_error
    
    ; AX = AX + BL
    add ax, bx
    
    inc si
    dec cl
    jnz stoi_loop
    
    clc                ; CF=0 => OK
    pop cx
    pop dx
    pop bx
    ret

stoi_error:
    stc                ; CF=1 => error
    pop cx
    pop dx
    pop bx
    ret
StrToInt endp

; ---------- IntToStr ----------
; AX = valor numérico a convertir
; DI = buffer destino (ej. out_buffer)
; Escribe cadena terminada en '$'
IntToStr proc
    push ax
    push bx
    push cx
    push dx
    push si

    ; Caso especial: número 0
    cmp ax, 0
    jne its_not_zero
    mov byte ptr [di], '0'
    mov byte ptr [di+1], '$'
    jmp its_done

its_not_zero:
    mov cx, 0          ; contador de dígitos

its_divloop:
    mov dx, 0
    mov bx, 10
    div bx             ; AX = AX/10, DX = resto (0-9)

    push dx            ; guardar resto en la pila
    inc cx             ; aumentar número de dígitos

    cmp ax, 0
    jne its_divloop

    ; ahora CX = número de dígitos
its_poploop:
    pop dx
    add dl, '0'        ; convertir resto a ASCII
    mov [di], dl
    inc di
    loop its_poploop

    mov byte ptr [di], '$'

its_done:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
IntToStr endp

end start
