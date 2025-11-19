# Documentación del Sistema Bancario en Ensamblador 8086

## Descripción General

Este programa implementa un sistema bancario básico en lenguaje ensamblador para la arquitectura 8086, diseñado para ejecutarse en el emulador emu8086. El sistema permite a un usuario autenticarse mediante un PIN y realizar operaciones bancarias básicas: consultar saldo, depositar dinero y retirar dinero.

## Funcionalidades Implementadas

### 1. Sistema de Autenticación (Login)

El programa implementa un sistema de login con las siguientes características:

- **PIN fijo**: El PIN correcto está almacenado en memoria como "1234"
- **3 intentos**: El usuario tiene máximo 3 intentos para ingresar el PIN correcto
- **Validación**: Se compara carácter por carácter el PIN ingresado con el PIN correcto
- **Bloqueo**: Si el usuario falla 3 veces, la cuenta se bloquea y el programa termina

**Flujo del login:**
1. Se muestra un mensaje pidiendo el PIN
2. El usuario ingresa 4 dígitos
3. Se valida que la longitud sea exactamente 4 caracteres
4. Se compara con el PIN correcto
5. Si es correcto, se permite el acceso al menú
6. Si es incorrecto, se resta un intento y se vuelve a pedir
7. Si se agotan los 3 intentos, se bloquea la cuenta

### 2. Menú Principal

Después de un login exitoso, el usuario accede a un menú con 4 opciones:

1. **Consultar saldo**: Muestra el saldo actual de la cuenta
2. **Depositar**: Permite agregar dinero a la cuenta
3. **Retirar**: Permite retirar dinero de la cuenta (con validación de fondos)
4. **Salir**: Termina el programa

El menú se repite hasta que el usuario seleccione la opción 4.

### 3. Operaciones Bancarias

#### Consultar Saldo
- Muestra el saldo actual almacenado en memoria
- El saldo se convierte de número a texto para mostrarlo

#### Depositar
- Solicita al usuario una cantidad a depositar
- Valida que la entrada sea numérica
- Suma la cantidad al saldo actual
- Muestra confirmación de la operación

#### Retirar
- Solicita al usuario una cantidad a retirar
- Valida que la entrada sea numérica
- Verifica que haya fondos suficientes
- Si hay fondos suficientes, resta la cantidad del saldo
- Si no hay fondos, muestra un mensaje de error y no realiza la operación

## Estructura del Programa

### Variables y Datos

- **CorrectPIN**: PIN correcto almacenado como cadena ("1234")
- **Balance**: Variable de tipo word (16 bits) que almacena el saldo actual (inicial: 1000)
- **pin_buffer**: Buffer para leer el PIN ingresado por el usuario
- **pin_len**: Variable que almacena la longitud real del PIN leído
- **pin_data**: Área donde se almacenan los caracteres del PIN
- **num_buffer**: Buffer para leer cantidades numéricas (depósitos/retiros)
- **num_len**: Variable que almacena la longitud real de la cantidad leída
- **num_data**: Área donde se almacenan los caracteres de la cantidad
- **out_buffer**: Buffer para convertir números a texto y mostrarlos
- **end_flag**: Bandera para controlar la salida del menú (0=continuar, 1=salir)
- **crlf**: Cadena con retorno de carro y salto de línea (13,10,"$")
- **msgContinuar**: Mensaje que pide al usuario presionar una tecla para continuar

### Subrutinas Principales

#### PrintStr
- **Propósito**: Imprime una cadena de texto terminada en '$'
- **Entrada**: DX contiene la dirección (offset) de la cadena
- **Uso**: Utiliza la interrupción 21h con función 09h

#### PrintCRLF
- **Propósito**: Imprime salto de línea (CR/LF)
- **Funcionamiento**: Utiliza la cadena `crlf` que contiene los caracteres 13,10 (retorno de carro y salto de línea) y los imprime usando PrintStr

#### ReadLine
- **Propósito**: Lee una línea de texto desde el teclado
- **Entrada**: DX contiene la dirección del buffer estructurado para DOS
- **Uso**: Utiliza la interrupción 21h con función 0Ah
- **Estructura del buffer**: 
  - Byte 0: Longitud máxima (incluyendo el Enter)
  - Byte 1: Longitud real leída (sin el Enter) - se almacena automáticamente por DOS
  - Bytes 2 en adelante: Los caracteres ingresados
- **Nota**: En el código, los buffers están estructurados con variables separadas (`pin_buffer`, `pin_len`, `pin_data`) que se mapean a esta estructura continua requerida por DOS

#### LoginPIN
- **Propósito**: Maneja el proceso de autenticación
- **Lógica**: 
  - Permite 3 intentos
  - Lee el PIN ingresado
  - Compara carácter por carácter con el PIN correcto
  - Retorna éxito (ZF=1) o fallo (ZF=0)

#### StrToInt
- **Propósito**: Convierte una cadena de dígitos ASCII a un número entero
- **Entrada**: 
  - SI: dirección del primer carácter numérico
  - CL: longitud de la cadena
- **Salida**: 
  - AX: valor numérico convertido
  - CF=0 si la conversión fue exitosa, CF=1 si hubo error
- **Funcionamiento**: 
  - Recorre cada carácter
  - Verifica que sea un dígito (0-9)
  - Multiplica el resultado acumulado por 10 y suma el nuevo dígito

#### IntToStr
- **Propósito**: Convierte un número entero a una cadena de texto
- **Entrada**: 
  - AX: número a convertir
  - DI: dirección del buffer de salida (aunque internamente usa `out_buffer`)
- **Salida**: Cadena de dígitos ASCII terminada en '$' en `out_buffer`
- **Funcionamiento**: 
  - Si el número es 0, maneja el caso especial escribiendo directamente '0'
  - Divide el número entre 10 repetidamente
  - Guarda cada resto (dígito) en un buffer temporal (al revés)
  - Copia los dígitos al buffer final en el orden correcto
  - Termina la cadena con '$'

#### MenuPrincipal
- **Propósito**: Muestra el menú y procesa la opción seleccionada
- **Funcionamiento**: 
  - Imprime el menú
  - Lee un carácter del teclado con INT 21h función 01h
  - Compara con '1', '2', '3', '4'
  - Llama a la función correspondiente
  - Si la opción es inválida, muestra mensaje de error y salto de línea
  - Si la opción es '4', establece la bandera `end_flag` en 1 para salir del programa

#### ConsultarSaldo
- **Propósito**: Muestra el saldo actual
- **Funcionamiento**: 
  - Obtiene el valor de Balance
  - Lo convierte a texto con IntToStr
  - Lo imprime en pantalla
  - Muestra mensaje para continuar
  - Espera a que el usuario presione una tecla (INT 16h)

#### Depositar
- **Propósito**: Agrega dinero al saldo
- **Funcionamiento**: 
  - Solicita la cantidad
  - Lee la entrada del usuario con ReadLine
  - Imprime salto de línea
  - Convierte a número con StrToInt
  - Valida que sea correcto
  - Suma al Balance
  - Muestra confirmación
  - Espera a que el usuario presione una tecla (INT 16h)

#### Retirar
- **Propósito**: Resta dinero del saldo
- **Funcionamiento**: 
  - Solicita la cantidad
  - Lee la entrada del usuario con ReadLine
  - Imprime salto de línea
  - Convierte a número con StrToInt
  - Valida que sea correcto
  - Compara con el saldo actual
  - Si hay fondos suficientes, resta del Balance y muestra confirmación
  - Si no hay fondos, muestra error
  - Espera a que el usuario presione una tecla (INT 16h) antes de regresar

## Aspectos Técnicos Importantes

### Interrupciones del Sistema Operativo (DOS)

El programa utiliza principalmente la interrupción **21h** de DOS:

- **AH=09h**: Imprimir cadena (requiere que termine en '$')
- **AH=0Ah**: Leer línea de texto (requiere buffer estructurado)
- **AH=01h**: Leer un carácter del teclado
- **AH=4Ch**: Terminar programa

También usa la interrupción **10h** de BIOS:
- **AX=0003h**: Limpiar pantalla y establecer modo texto 80x25 (se usa `mov ax, 3` seguido de `int 10h`)

Y la interrupción **16h** de BIOS:
- **AH=00h**: Leer carácter del teclado (espera hasta que se presione una tecla). Se usa para pausar la ejecución y permitir al usuario leer los mensajes antes de continuar.

### Manejo de Números

- Los números se almacenan como enteros de 16 bits (word), permitiendo valores de 0 a 65535
- Las conversiones entre texto y números son necesarias porque:
  - El usuario ingresa texto (ASCII)
  - Las operaciones se hacen con números binarios
  - La salida debe ser texto para mostrarse

### Validaciones

El programa incluye validaciones básicas:
- Longitud del PIN debe ser exactamente 4 caracteres
- Las cantidades deben ser números válidos (solo dígitos 0-9)
- Los retiros no pueden exceder el saldo disponible

## Limitaciones y Consideraciones

- El PIN está hardcodeado en el programa (no se puede cambiar sin recompilar)
- Solo maneja un saldo (no hay múltiples usuarios)
- No hay persistencia de datos (al cerrar el programa, el saldo vuelve al inicial)
- Las cantidades están limitadas a valores entre 0 y 65535
- No se valida overflow en depósitos (si el saldo excede 65535, habrá desbordamiento)

## Casos de Prueba

1. **Login correcto**: Ingresar PIN "1234" → debe permitir acceso
2. **Login fallido**: Ingresar PIN incorrecto 3 veces → debe bloquear cuenta
3. **Depósito válido**: Depositar 500 con saldo inicial 1000 → saldo final 1500
4. **Retiro válido**: Retirar 200 con saldo 1500 → saldo final 1300
5. **Retiro sin fondos**: Intentar retirar 200 con saldo 100 → debe mostrar error
6. **Entrada inválida**: Ingresar letras en depósito/retiro → debe mostrar error

## Conclusión

Este programa demuestra los conceptos fundamentales de programación en ensamblador:
- Manejo de registros y memoria
- Uso de interrupciones del sistema operativo
- Conversión entre diferentes representaciones de datos (ASCII/binario)
- Estructuración del código en subrutinas
- Validación de entrada del usuario
- Control de flujo con saltos condicionales

Es un proyecto educativo que permite entender cómo funciona la computadora a bajo nivel, mostrando cómo las instrucciones simples del procesador se combinan para crear funcionalidades más complejas.

