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

CorrectPIN      db  "1234"      ; PIN correcto (4 bytes)
Balance         dw  1000        ; saldo inicial: 1000

; Buffer DOS para leer PIN (funci�n 0Ah)
; Estructura: [0]=max, [1]=longitud real, [2..]=datos
pin_buffer      db  5           ; max 5 chars (4 + Enter)
pin_len         db  ?           ; longitud real introducida
pin_data        db  5 dup(?)    ; aqu� se almacenan los caracteres

; Buffer para cantidades
num_buffer      db  6           ; max 6 chars (hasta 65535)
num_len         db  ?
num_data        db  6 dup(?)

; Buffer para imprimir n�meros (resultado de IntToStr)
out_buffer      db  6 dup('$')  ; terminaremos con '$'

; Bandera para salir del men�
end_flag        db  0           ; 0 = seguir en menu, 1 = salir

; ========= C�DIGO =========
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
    
    ; Esperar tecla antes de mostrar el men
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
; Prop�sito: Imprime una cadena de caracteres terminada en '$' en la consola
; Par�metros: DX = offset de la cadena a imprimir
; Registros modificados: AH (09h), utiliza interrupci�n 21h
PrintStr proc
    mov ah, 09h
    int 21h
    ret
PrintStr endp

; ---------- Subrutina: PrintCRLF ----------
; Prop�sito: Imprime un salto de l�nea (carriage return + line feed)
; Par�metros: Ninguno
; Registros modificados: DX, AH (09h), utiliza interrupci�n 21h
PrintCRLF proc
    mov dx, offset crlf
    mov ah, 09h
    int 21h
    ret
PrintCRLF endp

crlf db 13,10, "$"

; ---------- Subrutina: ReadLine (usa buffer DOS) ----------
; Prop�sito: Lee una l�nea de texto desde el teclado usando buffer DOS (funci�n 0Ah)
; Par�metros: DX = offset del buffer estructurado (primer byte = tama�o m�ximo)
; Registros modificados: AH (0Ah), utiliza interrupci�n 21h. El buffer se modifica con la entrada del usuario
ReadLine proc
    mov ah, 0Ah
    int 21h
    ret
ReadLine endp

; ---------- Subrutina: LoginPIN ----------
; Prop�sito: Autentica al usuario solicitando PIN. Permite hasta 3 intentos
; Par�metros: Ninguno (usa variables globales: pin_buffer, CorrectPIN)
; Registros modificados: AX, CX, SI, DI, BX, AL, ZF. Retorna ZF=1 si login exitoso, ZF=0 si fall�
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
    
    ; si llegamos aqu�, PIN correcto
    ; ZF=1 para indicar �xito
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
; Prop�sito: Muestra el men� principal y procesa la opci�n seleccionada por el usuario
; Par�metros: Ninguno (lee entrada del teclado)
; Registros modificados: DX, AH, AL. Modifica end_flag si se selecciona salir
MenuPrincipal proc
    mov dx, offset msgMenu
    call PrintStr
    
    ; Leer una tecla
    mov ah, 01h
    int 21h            ; AL = tecla
    
    ; Consumir el salto de lnea si el usuario presion Enter
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
    call PrintCRLF     ; salto de l�nea despu�s de leer
    
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
; Prop�sito: Muestra el saldo actual de la cuenta en pantalla
; Par�metros: Ninguno (lee Balance desde variable global)
; Registros modificados: DX, AX, DI. Utiliza out_buffer para formatear el n�mero
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

msgContinuar db 13,10, "Presiona cualquier tecla para continuar...$"

; ---------- Depositar ----------
; Prop�sito: Permite al usuario depositar una cantidad de dinero en su cuenta
; Par�metros: Ninguno (lee cantidad desde num_buffer usando ReadLine)
; Registros modificados: DX, CL, SI, AX, AH. Modifica Balance (variable global)
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
; Prop�sito: Permite al usuario retirar una cantidad de dinero de su cuenta (valida fondos suficientes)
; Par�metros: Ninguno (lee cantidad desde num_buffer usando ReadLine)
; Registros modificados: DX, CL, SI, AX, BX, AH. Modifica Balance (variable global)
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
; Prop�sito: Convierte una cadena de d�gitos ASCII a su valor num�rico entero (16 bits)
; Par�metros: SI = offset del primer d�gito de la cadena, CL = longitud de la cadena
; Registros modificados: AX, BX, DX, CX (preservados con push/pop). Retorna AX = valor num�rico, CF=1 si error, CF=0 si OK
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
    
    sub bl, '0'        ; ahora BL = valor num�rico (0-9)
    mov bh, 0          ; extender a 16 bits
    
    ; Validar desbordamiento antes de multiplicar
    ; Si AX > 6553, entonces AX * 10 > 65535 (desbordamiento)
    cmp ax, 6553
    ja stoi_error
    
    ; AX = AX * 10
    mov dx, ax
    shl ax, 1          ; AX = AX*2
    shl dx, 3          ; DX = AX*8 (usando copia)
    add ax, dx         ; AX = AX*10
    
    ; Validar desbordamiento antes de sumar
    ; Si AX > 65535 - BX, entonces AX + BX > 65535
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
; Prop�sito: Convierte un n�mero entero (16 bits) a su representaci�n en cadena ASCII
; Par�metros: AX = valor num�rico a convertir, DI = offset del buffer de salida
; Registros modificados: AX, BX, CX, DX, SI, DI (preservados con push/pop). El buffer apuntado por DI se modifica con el resultado
IntToStr proc
    push ax
    push bx
    push cx
    push dx
    push si
    
    ; Buffer temporal para construir el n�mero al rev�s
    mov si, offset out_buffer
    add si, 5          ; empezar desde el final del buffer
    mov byte ptr [si], '$'  ; terminar con $
    dec si              ; posici�n para el �ltimo d�gito
    
    ; Si el n�mero es 0, caso especial
    cmp ax, 0
    jne its_loop
    mov byte ptr [si], '0'
    ; Copiar al buffer final (usar DI original)
    pop di              ; recuperar DI original
    mov al, [si]
    mov [di], al
    mov byte ptr [di+1], '$'
    jmp its_done

its_loop:
    cmp ax, 0
    je its_copiar
    
    mov dx, 0
    mov bx, 10
    div bx             ; AX = AX/10, DX = resto (0-9)
    
    add dl, '0'        ; convertir resto a ASCII
    mov [si], dl       ; guardar d�gito (al rev�s)
    dec si
    
    jmp its_loop

its_copiar:
    ; Los d�gitos est�n al rev�s, copiarlos al inicio del buffer
    inc si              ; apuntar al primer d�gito guardado
    mov di, offset out_buffer
    
its_copy:
    mov al, [si]
    cmp al, '$'
    je its_done
    mov [di], al
    inc si
    inc di
    jmp its_copy

its_done:
    mov byte ptr [di], '$'  ; asegurar terminaci�n con $
    
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
IntToStr endp