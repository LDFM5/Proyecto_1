;******************************************************************************
; Universidad del Valle de Guatemala
; Programación de Microcrontroladores
; Proyecto: Lab3
; Archivo: main.asm
; Hardware: ATMEGA328p
; Created: 13/02/2024 18:35:16
; Author : Luis Furlán
;******************************************************************************
; Encabezado
;******************************************************************************

.include "M328PDEF.inc"
.cseg //Indica inicio del código
.org 0x00 //Indica el RESET
	JMP Main
.org 0x0008 // Vector de ISR : PCINT1
	JMP ISR_PCINT1
.org 0x001A // Vector de ISR : TIMER1_OVF
	JMP ISR_TIMER_OVF1
.org 0x0020 // Vector de ISR : TIMER0_OVF
	JMP ISR_TIMER_OVF0
	
Main:
;******************************************************************************
; Stack
;******************************************************************************
LDI R16, LOW(RAMEND)
OUT SPL, R16 
LDI R17, HIGH(RAMEND)
OUT SPH, R17
;******************************************************************************
; Configuración
;******************************************************************************
Setup:
	LDI R16, (1 << CLKPCE)
	STS CLKPR, R16 ;HABILITAMOS EL PRESCALER
	LDI R16, 0b0000_0100
	STS CLKPR, R16 ; DEFINIMOS UNA FRECUENCIA DE 1MGHz

	LDI R16, 0x3C ; CONFIGURAMOS LOS PULLUPS en PORTC
	OUT PORTC, R16	; HABILITAMOS EL PULLUPS
	LDI R16, 0b0000_0011
	OUT DDRC, R16	;Puertos C (entradas y salidas)

	LDI R16, 0xFF
	OUT DDRD, R16	;Puertos D (entradas y salidas)

	LDI R16, 0x2F
	OUT DDRB, R16	;Puertos B (entradas y salidas)

	CLR R16
	LDI R16, (1 << PCIE1)
	STS PCICR, R16 //Configurar PCIE1

	CLR R16
	LDI R16, (1 << PCINT10) | (1 << PCINT11) | (1 << PCINT12) | (1 << PCINT13)
	STS PCMSK1, R16 //Habilitar la interrupción para los pines correspondientes

	CLR R16
	LDI R16, (1 << TOIE0)
	STS TIMSK0, R16 //Habilitar interrupción de overflow para timer0

	LDI R16, (1 << TOIE1)
	STS TIMSK1, R16 //Habilitar interrupción de overflow para timer1

	//timer 1
	CLR R16
	STS TCCR1A, R16 ; modo normal

	CLR R16
	LDI R16, (1 << CS12 | 1 << CS10)
	STS TCCR1B, R16 ; prescaler 1024

	LDI R16, 0x1B ; valor calculado donde inicia a contar
	//LDI R16, 0xFF ; valor calculado donde inicia a contar
	STS TCNT1H, R16
	LDI R16, 0x1E ; valor calculado donde inicia a contar
	//LDI R16, 0xFF ; valor calculado donde inicia a contar
	STS TCNT1L, R16

	//timer 0
	CLR R16
	OUT TCCR0A, R16 ; modo normal

	CLR R16
	LDI R16, (1 << CS02 | 1 << CS00)
	OUT TCCR0B, R16 ; prescaler 1024

	LDI R16, 251 ; valor calculado donde inicia a contar
	OUT TCNT0, R16

	//Deshabilitar Tx y Rx
	LDI R16, (0 << RXEN0) | (0 << TXEN0) 
    STS UCSR0B, R16

	SEI // Habilitar interruciones globales GIE
	
// Representaciones de los números hexadecimales para el display
	tabla: .DB 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F, 0x77, 0x7C, 0x39, 0x5E, 0x79, 0x71 

	LDI ZH, HIGH(tabla << 1)
	LDI ZL, LOW(tabla << 1)
	MOV R21, ZL
	MOV R25, ZL
	MOV R26, ZL
	MOV R27, ZL
	LDI R16, 1
	MOV R28, ZL
	ADD R28, R16
	MOV R29, ZL
	MOV R23, ZL
	ADD R23, R16
	MOV R18, ZL
	STS 0x0100, ZL
	STS 0x0101, ZL
	STS 0x0102, ZL
	STS 0x0103, ZL
	LPM R19, Z
	OUT PORTD, R19

	CLR R16
	CLR R17
	CLR R20
	CLR R22
	CLR R24

	SBI PORTB, PB0
	SBI PORTB, PB1
	SBI PORTB, PB2
	SBI PORTB, PB3
	
Loop:
	CPI R22, 0
	BREQ reloj
	CPI R22, 3
	BREQ config_reloj_hora
	CPI R22, 4
	BREQ config_reloj_min
	CPI R22, 1
	BREQ puente_fecha
	CPI R22, 5
	BREQ puente_config_fecha_dia
	CPI R22, 6
	BREQ puente_config_fecha_mes
	CPI R22, 7
	BREQ puente_config_alarma_hora
	CPI R22, 8
	BREQ puente_config_alarma_min
	CPI R22, 2
	BREQ puente_alarma
	RJMP Loop
reloj:
	SBI PORTC, PC1
	CBI PORTC, PC0
	SBRS R24, 3
	CBI PORTB, PB5
	CPI R20, 1
	BREQ puente2_revisar
	CPI R20, 2
	BREQ puente2_min_unid
	SBRC R24, 5
	RJMP puente_apagar_alarma
	SBRC R24, 6
	RJMP cambiar_modo
	SBRC R24, 1
	LDI R22, 3
	CBR R24, 0b0000_0010
	SBRC R24, 4
	RJMP check_alarma
	RJMP Loop
config_reloj_hora:
	CPI R20, 1
	BREQ puente2_revisar
	SBRC R24, 6
	LDI R22, 4
	CBR R24, 0b0100_0000
	SBRC R24, 5
	LDI R22, 0
	CBR R24, 0b0010_0000
	SBRC R24, 0
	RJMP puente_hor_unid
	SBRC R24, 1
	RJMP puente_dec_hor_unid
	RJMP Loop
config_reloj_min:
	CPI R20, 1
	BREQ puente3_revisar
	SBRC R24, 6
	LDI R22, 3
	CBR R24, 0b0100_0000
	SBRC R24, 5
	LDI R22, 0
	CBR R24, 0b0010_0000
	SBRC R24, 0
	RJMP puente_min_unid
	SBRC R24, 1
	RJMP puente_dec_min_unid
	RJMP Loop
//puente
puente_fecha:
	RJMP fecha
puente_config_fecha_mes:
	RJMP config_fecha_mes
puente_config_fecha_dia:
	RJMP config_fecha_dia
puente_config_alarma_min:
	RJMP config_alarma_min
puente_config_alarma_hora:
	RJMP config_alarma_hora
puente2_revisar:
	RJMP puente_revisar
puente_apagar_alarma:
	RJMP apagar_alarma
puente2_min_unid:
	RJMP puente_min_unid
puente_alarma:
	RJMP alarma
puente3_revisar:
	RJMP puente_revisar
//----------
fecha:
	CBI PORTC, PC1
	SBI PORTC, PC0
	SBRS R24, 3
	CBI PORTB, PB5
	CPI R20, 1
	BREQ puente_revisar_fecha
	CPI R20, 2
	BREQ puente_min_unid
	SBRC R24, 1
	LDI R22, 5
	CBR R24, 0b0000_0010
	SBRC R24, 5
	RJMP apagar_alarma
	SBRC R24, 6
	RJMP cambiar_modo
	SBRC R24, 4
	RJMP check_alarma
	RJMP Loop
config_fecha_dia:
	CPI R20, 1
	BREQ puente_revisar_fecha
	SBRC R24, 0
	RJMP puente_dia_unid
	SBRC R24, 6
	LDI R22, 6
	CBR R24, 0b0100_0000
	SBRC R24, 5
	LDI R22, 1
	CBR R24, 0b0010_0000
	SBRC R24, 1
	RJMP puente_dec_dia_unid
	RJMP Loop
config_fecha_mes:
	CPI R20, 1
	BREQ puente_revisar_fecha
	SBRC R24, 0
	RJMP puente_mes_unid
	SBRC R24, 6
	LDI R22, 5
	CBR R24, 0b0100_0000
	SBRC R24, 5
	LDI R22, 1
	CBR R24, 0b0010_0000
	SBRC R24, 1
	RJMP puente_dec_mes_unid
	RJMP Loop
alarma:
	CBI PORTC, PC1
	CBI PORTC, PC0
	SBI PORTB, PB5
	CPI R20, 1
	BREQ puente_revisar_alarma
	CPI R20, 2
	BREQ puente_min_unid
	SBRC R24, 1
	LDI R22, 7
	CBR R24, 0b0000_0010
	SBRC R24, 0
	CBR R24, 0b0001_0000
	CBR R24, 0b0000_0001
	SBRC R24, 6
	RJMP cambiar_modo
	SBRC R24, 5
	RJMP armar_alarma
	RJMP Loop
//-----Puentes-----
puente_revisar_fecha:
	RJMP revisar_fecha
puente_min_unid:
	RJMP min_unid
puente_revisar:
	RJMP revisar
puente_hor_unid:
	RJMP hor_unid
puente_dec_hor_unid:
	RJMP dec_hor_unid
puente_dec_min_unid:
	RJMP dec_min_unid
puente_revisar_alarma:
	RJMP revisar_alarma
//-----------------
config_alarma_hora:
	CPI R20, 1
	BREQ revisar_alarma
	CPI R20, 2
	BREQ puente_min_unid
	SBRC R24, 6
	LDI R22, 8
	CBR R24, 0b0100_0000
	SBRC R24, 5
	LDI R22, 2
	CBR R24, 0b0010_0000
	SBRC R24, 0
	RJMP hor_unid_alarma
	SBRC R24, 1
	RJMP dec_hor_unid_alarma
	RJMP Loop
config_alarma_min:
	CPI R20, 1
	BREQ revisar_alarma
	CPI R20, 2
	BREQ puente_min_unid
	SBRC R24, 6
	LDI R22, 7
	CBR R24, 0b0100_0000
	SBRC R24, 5
	LDI R22, 2
	CBR R24, 0b0010_0000
	SBRC R24, 0
	RJMP min_unid_alarma
	SBRC R24, 1
	RJMP dec_min_unid_alarma
	RJMP Loop

cambiar_modo:
	CBR R24, 0b0100_0000
	CPI R22, 2
	BREQ rst_modo
	INC R22
	RJMP Loop
	rst_modo:
	CLR R22
	RJMP Loop
	
apagar_alarma:
	CBR R24, 0b0010_0000
	SBRC R24, 3
	CBR R24, 0b0001_0000
	CBR R24, 0b0000_1000
	CBI PORTB, PB4
	CBI PORTB, PB5
	RJMP Loop

armar_alarma:
	SBRS R24, 4
	SBI PORTB, PB4
	CBR R24, 0b0010_0000
	SBR R24, 0b0001_0000
	RJMP Loop
;******************************************************************************
; Subrutinas (funciones)
;******************************************************************************

//--------Multiplexeado alarma--------
revisar_alarma: //revisa cual display está encendido
	CLR R20
	SBIS PORTB, PB0
	RJMP display2_alarma
	RJMP unidades_hor_alarma
display2_alarma:
	SBIS PORTB, PB1
	RJMP display3_alarma
	RJMP decenas_min_alarma
display3_alarma:
	SBIS PORTB, PB2
	RJMP decenas_hor_alarma
	RJMP unidades_min_alarma

unidades_min_alarma:
	CBI PORTB, PB0
	CBI PORTB, PB1
	CBI PORTB, PB2
	SBI PORTB, PB3
	LDS ZL, 0x0100
	LPM R19, Z
	CPI R22, 8
	BREQ puente2_parpadeo
	RJMP display7
decenas_min_alarma:
	CBI PORTB, PB0
	CBI PORTB, PB1
	SBI PORTB, PB2
	CBI PORTB, PB3
	LDS ZL, 0x0101
	LPM R19, Z
	CPI R22, 8
	BREQ puente2_parpadeo
	RJMP display7
unidades_hor_alarma:
	CBI PORTB, PB0
	SBI PORTB, PB1
	CBI PORTB, PB2
	CBI PORTB, PB3
	LDS ZL, 0x0102
	LPM R19, Z
	CPI R22, 7
	BREQ puente2_parpadeo
	RJMP display7
	
decenas_hor_alarma:
	SBI PORTB, PB0
	CBI PORTB, PB1
	CBI PORTB, PB2
	CBI PORTB, PB3
	LDS ZL, 0x0103
	LPM R19, Z
	CPI R22, 7
	BREQ puente2_parpadeo
	RJMP display7

//----------Alarma----------
min_unid_alarma:
	CLR R20
	CBR R24, 0000_0001
	LDS R16, 0x0100
	INC R16
	STS 0x0100, R16
	MOV ZL, R16
	LPM R19, Z
	CPI R19, 0x77
	BREQ rst_min_unid_alarma
	RJMP Loop
rst_min_unid_alarma:
	LDS R16, 0x0100
	LDI R16, LOW(tabla << 1)
	STS 0x0100, R16
	RJMP min_dec_alarma//-----------------------------------------------------------------
	
//-----puentes-----
puente2_parpadeo:
	RJMP parpadeo
//-----------------

min_dec_alarma: 
	LDS R16, 0x0101
	INC R16
	STS 0x0101, R16
	MOV ZL, R16
	LPM R19, Z
	CPI R19, 0x7D
	BREQ rst_min_dec_alarma
	RJMP Loop
rst_min_dec_alarma:
	LDS R16, 0x0101
	LDI R16, LOW(tabla << 1)
	STS 0x0101, R16
	RJMP Loop

hor_unid_alarma:
	CBR R24, 0b0000_0001
	LDS R16, 0x0102
	INC R16
	STS 0x0102, R16
	LDS ZL, 0x0103
	LPM R19, Z
	CPI R19, 0x5B
	BREQ rst_hor_unid2_alarma
	RJMP rst_hor_unid1_alarma
rst_hor_unid2_alarma:
	MOV ZL, R16
	LPM R19, Z
	CPI R19, 0x66
	BREQ rst_hor_unid_alarma
	RJMP Loop
rst_hor_unid1_alarma:
	MOV ZL, R16
	LPM R19, Z
	CPI R19, 0x77
	BREQ rst_hor_unid_alarma
	RJMP Loop
rst_hor_unid_alarma:
	LDS R16, 0x0102
	LDI R16, LOW(tabla << 1)
	STS 0x0102, R16
	RJMP hor_dec_alarma

hor_dec_alarma:  
	LDS R16, 0x0103
	INC R16
	STS 0x0103, R16
	MOV ZL, R16
	LPM R19, Z
	CPI R19, 0x4F
	BREQ rst_hor_dec_alarma
	RJMP Loop
rst_hor_dec_alarma:
	LDS R16, 0x0103
	LDI R16, LOW(tabla << 1)
	STS 0x0103, R16
	RJMP Loop

dec_hor_unid_alarma:
	CBR R24, 0b0000_0010
	LDS ZL, 0x0102
	LPM R19, Z
	CPI R19, 0x3F
	BREQ rst_dec_hor_unid_alarma
	LDS R16, 0x0102
	DEC R16
	STS 0x0102, R16
	RJMP Loop
rst_dec_hor_unid_alarma:
	LDS ZL, 0x0103
	LPM R19, Z
	CPI R19, 0x3F
	BREQ rst_dec_hor_unid2_alarma
	RJMP rst_dec_hor_unid1_alarma
rst_dec_hor_unid2_alarma:
	PUSH R17
	LDS R16, 0x0102
	LDI R16, LOW(tabla << 1)
	LDI R17, 3
	ADD R16, R17
	STS 0x0102, R16
	POP R17
	RJMP dec_hor_dec_alarma
rst_dec_hor_unid1_alarma:
	PUSH R17
	LDS R16, 0x0102
	LDI R16, LOW(tabla << 1)
	LDI R17, 9
	ADD R16, R17
	STS 0x0102, R16
	POP R17
	RJMP dec_hor_dec_alarma

dec_hor_dec_alarma:  
	LDS ZL, 0x0103
	LPM R19, Z
	CPI R19, 0x3F
	BREQ rst_dec_hor_dec_alarma
	LDS R16, 0x0103
	DEC R16
	STS 0x0103, R16
	RJMP Loop
rst_dec_hor_dec_alarma:
	PUSH R17
	LDS R16, 0x0103
	LDI R16, LOW(tabla << 1)
	LDI R17, 2
	ADD R16, R17
	STS 0x0103, R16
	POP R17
	RJMP Loop

dec_min_unid_alarma:
	CBR R24, 0b0000_0010
	LDS ZL, 0x0100
	LPM R19, Z
	CPI R19, 0x3F
	BREQ rst_dec_min_unid_alarma
	LDS R16, 0x0100
	DEC R16
	STS 0x0100, R16
	RJMP Loop
rst_dec_min_unid_alarma:
	PUSH R17
	LDS R16, 0x0100
	LDI R16, LOW(tabla << 1)
	LDI R17, 9
	ADD R16, R17
	STS 0x0100, R16
	POP R17
	RJMP dec_min_dec_alarma

dec_min_dec_alarma:
	LDS ZL, 0x0101
	LPM R19, Z
	CPI R19, 0x3F
	BREQ rst_dec_min_dec_alarma
	LDS R16, 0x0101
	DEC R16
	STS 0x0101, R16
	RJMP Loop
rst_dec_min_dec_alarma:
	PUSH R17
	LDS R16, 0x0101
	LDI R16, LOW(tabla << 1)
	LDI R17, 5
	ADD R16, R17
	STS 0x0101, R16
	POP R17
	RJMP Loop

;----------Chequeo de alarma----------
check_alarma:
	LDS R16, 0x0100
	CP R16, R21
	BREQ disp2
	RJMP Loop
disp2:
	LDS R16, 0x0101
	CP R16, R25
	BREQ disp3
	RJMP Loop
disp3:
	LDS R16, 0x0102
	CP R16, R26
	BREQ disp4
	RJMP Loop
disp4:
	LDS R16, 0x0103
	CP R16, R27
	BREQ enc_alarma
	RJMP Loop
enc_alarma:
	SBR R24, 0b0000_1000
	RJMP Loop

;----------Multiplexado hora----------
revisar: //revisa cual display está encendido
	CLR R20
	SBIS PORTB, PB0
	RJMP display2
	RJMP unidades_hor
display2:
	SBIS PORTB, PB1
	RJMP display3
	RJMP decenas_min
display3:
	SBIS PORTB, PB2
	RJMP decenas_hor
	RJMP unidades_min

unidades_min:
	CBI PORTB, PB0
	CBI PORTB, PB1
	CBI PORTB, PB2
	SBI PORTB, PB3
	MOV ZL, R21
	LPM R19, Z
	CPI R22, 4
	BREQ parpadeo
	RJMP display7
decenas_min:
	CBI PORTB, PB0
	CBI PORTB, PB1
	SBI PORTB, PB2
	CBI PORTB, PB3
	MOV ZL, R25
	LPM R19, Z
	CPI R22, 4
	BREQ parpadeo
	RJMP display7
unidades_hor:
	CBI PORTB, PB0
	SBI PORTB, PB1
	CBI PORTB, PB2
	CBI PORTB, PB3
	MOV ZL, R26
	LPM R19, Z
	CPI R22, 3
	BREQ parpadeo
	RJMP display7
	
decenas_hor:
	SBI PORTB, PB0
	CBI PORTB, PB1
	CBI PORTB, PB2
	CBI PORTB, PB3
	MOV ZL, R27
	LPM R19, Z
	CPI R22, 3
	BREQ parpadeo
	RJMP display7

parpadeo:
	SBRS R24, 2
	RJMP ap_multi
	RJMP display7
ap_multi:
	CLR R19
	RJMP display7

;***********************************reloj*******************************************

min_unid:
	CLR R20
	CBR R24, 0000_0001
	INC R21
	MOV ZL, R21
	LPM R19, Z
	CPI R19, 0x77
	BREQ rst_min_unid
	RJMP Loop
rst_min_unid:
	LDI R21, LOW(tabla << 1)
	RJMP min_dec
	
min_dec: 
	INC R25
	MOV ZL, R25
	LPM R19, Z
	CPI R19, 0x7D
	BREQ rst_min_dec
	RJMP Loop
rst_min_dec:
	LDI R25, LOW(tabla << 1)
	CPI R22, 0
	BREQ hor_unid
	CPI R22, 3
	BREQ hor_unid
	RJMP Loop

hor_unid:
	CBR R24, 0b0000_0001
	INC R26
	MOV ZL, R27
	LPM R19, Z
	CPI R19, 0x5B
	BREQ rst_hor_unid2
	RJMP rst_hor_unid1
rst_hor_unid2:
	MOV ZL, R26
	LPM R19, Z
	CPI R19, 0x66
	BREQ rst_hor_unid
	RJMP Loop
rst_hor_unid1:
	MOV ZL, R26
	LPM R19, Z
	CPI R19, 0x77
	BREQ rst_hor_unid
	RJMP Loop
rst_hor_unid:
	LDI R26, LOW(tabla << 1)
	RJMP hor_dec

hor_dec:  
	INC R27
	MOV ZL, R27
	LPM R19, Z
	CPI R19, 0x4F
	BREQ rst_hor_dec
	RJMP Loop
rst_hor_dec:
	LDI R27, LOW(tabla << 1)
	CPI R22, 0
	BREQ puente_dia_unid
	CPI R22, 3
	BREQ puente_dia_unid
	RJMP Loop

dec_hor_unid:
	CBR R24, 0b0000_0010
	MOV ZL, R26
	LPM R19, Z
	CPI R19, 0x3F
	BREQ rst_dec_hor_unid
	DEC R26
	RJMP Loop
rst_dec_hor_unid:
	MOV ZL, R27
	LPM R19, Z
	CPI R19, 0x3F
	BREQ rst_dec_hor_unid2
	RJMP rst_dec_hor_unid1
rst_dec_hor_unid2:
	LDI R16, 3
	LDI R26, LOW(tabla << 1)
	ADD R26, R16
	RJMP dec_hor_dec
rst_dec_hor_unid1:
	LDI R16, 9
	LDI R26, LOW(tabla << 1)
	ADD R26, R16
	RJMP dec_hor_dec

dec_hor_dec:  
	MOV ZL, R27
	LPM R19, Z
	CPI R19, 0x3F
	BREQ rst_dec_hor_dec
	DEC R27
	RJMP Loop
rst_dec_hor_dec:
	LDI R16, 2
	LDI R27, LOW(tabla << 1)
	ADD R27, R16
	RJMP Loop

dec_min_unid:
	CBR R24, 0b0000_0010
	MOV ZL, R21
	LPM R19, Z
	CPI R19, 0x3F
	BREQ rst_dec_min_unid
	DEC R21
	RJMP Loop
rst_dec_min_unid:
	LDI R16, 9
	LDI R21, LOW(tabla << 1)
	ADD R21, R16
	RJMP dec_min_dec

dec_min_dec:  
	MOV ZL, R25
	LPM R19, Z
	CPI R19, 0x3F
	BREQ rst_dec_min_dec
	DEC R25
	RJMP Loop
rst_dec_min_dec:
	LDI R16, 5
	LDI R25, LOW(tabla << 1)
	ADD R25, R16
	RJMP Loop

//-----puentes-----
puente_parpadeo:
	RJMP parpadeo
puente_dia_unid:
	RJMP dia_unid
puente_dec_dia_unid:
	RJMP dec_dia_unid
puente_mes_unid:
	RJMP mes_unid
puente_dec_mes_unid:
	RJMP dec_mes_unid
//-----------------

;----------Multiplexado fecha----------
revisar_fecha: //revisa cual display está encendido
	CLR R20
	SBIS PORTB, PB0
	RJMP display2_fecha
	RJMP unidades_dia
display2_fecha:
	SBIS PORTB, PB1
	RJMP display3_fecha
	RJMP decenas_mes
display3_fecha:
	SBIS PORTB, PB2
	RJMP decenas_dia
	RJMP unidades_mes

unidades_mes:
	CBI PORTB, PB0
	CBI PORTB, PB1
	CBI PORTB, PB2
	SBI PORTB, PB3
	MOV ZL, R28
	LPM R19, Z
	CPI R22, 6
	BREQ puente_parpadeo
	RJMP display7
decenas_mes:
	CBI PORTB, PB0
	CBI PORTB, PB1
	SBI PORTB, PB2
	CBI PORTB, PB3
	MOV ZL, R29
	LPM R19, Z
	CPI R22, 6
	BREQ puente_parpadeo
	RJMP display7
unidades_dia:
	CBI PORTB, PB0
	SBI PORTB, PB1
	CBI PORTB, PB2
	CBI PORTB, PB3
	MOV ZL, R23
	LPM R19, Z
	CPI R22, 5
	BREQ puente_parpadeo
	RJMP display7
	
decenas_dia:
	SBI PORTB, PB0
	CBI PORTB, PB1
	CBI PORTB, PB2
	CBI PORTB, PB3
	MOV ZL, R18
	LPM R19, Z
	CPI R22, 5
	BREQ puente_parpadeo
	RJMP display7

;******************************************************************************

display7: //Muestra el valor del contador en el display
	SBIS PORTD, PD7
	RJMP ap_pts
	RJMP enc_pts
enc_pts:
	OUT PORTD, R19
	SBI PORTD, PD7
	RJMP puntos
ap_pts:
	OUT PORTD, R19
	CBI PORTD, PD7
	RJMP puntos

//parpadeo de 2 puntos
puntos:
	CPI R17, 100
	BREQ ac_puntos
	INC R17
	RJMP Loop
ac_puntos:
	CLR R17
	SBIS PORTD, PD7
	RJMP enc_puntos
	RJMP ap_puntos
enc_puntos:
	SBRC R24, 3
	SBI PORTB, PB4
	SBRC R24, 3
	SBI PORTB, PB5
	CBR R24, 0b0000_0100
	SBI PORTD, PD7
	CPI R22, 3
	BREQ ap_led1
	CPI R22, 4
	BREQ ap_led1
	CPI R22, 5
	BREQ ap_led2
	CPI R22, 6
	BREQ ap_led2
	CPI R22, 7
	BREQ ap_led3
	CPI R22, 8
	BREQ ap_led3
	RJMP Loop
enc_led1:
	SBI PORTC, PC1
	RJMP Loop
enc_led2:
	SBI PORTC, PC0
	RJMP Loop
enc_led3:
	SBI PORTB, PB5
	RJMP Loop
ap_puntos:
	CBI PORTB, PB4
	CBI PORTB, PB5
	SBR R24, 0b0000_0100
	CBI PORTD, PD7
	CPI R22, 3
	BREQ enc_led1
	CPI R22, 4
	BREQ enc_led1
	CPI R22, 5
	BREQ enc_led2
	CPI R22, 6
	BREQ enc_led2
	CPI R22, 7
	BREQ enc_led3
	CPI R22, 8
	BREQ enc_led3
	RJMP Loop
ap_led1:
	CBI PORTC, PC1
	RJMP Loop
ap_led2:
	CBI PORTC, PC0
	RJMP Loop
ap_led3:
	CBI PORTB, PB5
	RJMP Loop

//-------fecha-------
dia_unid:
	CBR R24, 0b0000_0001
	INC R23
	MOV ZL, R29
	LPM R19, Z
	CPI R19, 0x3F
	BREQ primeros_meses
	RJMP siguentes_meses
	primeros_meses:
	MOV ZL, R28
	LPM R19, Z
	CPI R19, 0x06 
	BREQ dias31
	CPI R19, 0x4F 
	BREQ dias31
	CPI R19, 0x6D
	BREQ dias31
	CPI R19, 0x07
	BREQ dias31
	CPI R19, 0x7F
	BREQ dias31
	CPI R19, 0x5B
	BREQ dias28
	CPI R19, 0x66
	BREQ dias30
	CPI R19, 0x7D
	BREQ dias30
	CPI R19, 0x6F
	BREQ dias30
	siguentes_meses:
	MOV ZL, R28
	LPM R19, Z
	CPI R19, 0x3F
	BREQ dias31
	CPI R19, 0x5B
	BREQ dias31
	CPI R19, 0x06
	BREQ dias30

	dias28:
	MOV ZL, R18
	LPM R19, Z
	CPI R19, 0x5B
	BREQ rst_dias28
	RJMP rst_dia28
	rst_dias28:
	MOV ZL, R23
	LPM R19, Z
	CPI R19, 0x6F
	BREQ rst_dia_unid
	RJMP Loop
	rst_dia28:
	MOV ZL, R23
	LPM R19, Z
	CPI R19, 0x77
	BREQ rst_dia_unid0
	RJMP Loop
	
	dias30:
	MOV ZL, R18
	LPM R19, Z
	CPI R19, 0x4F
	BREQ rst_dias30
	RJMP rst_dia30
	rst_dias30:
	MOV ZL, R23
	LPM R19, Z
	CPI R19, 0x06
	BREQ rst_dia_unid
	RJMP Loop
	rst_dia30:
	MOV ZL, R23
	LPM R19, Z
	CPI R19, 0x77
	BREQ rst_dia_unid0
	RJMP Loop

	dias31:
	MOV ZL, R18
	LPM R19, Z
	CPI R19, 0x4F
	BREQ rst_dias31
	RJMP rst_dia31
	rst_dias31:
	MOV ZL, R23
	LPM R19, Z
	CPI R19, 0x5B
	BREQ rst_dia_unid
	RJMP Loop
	rst_dia31:
	MOV ZL, R23
	LPM R19, Z
	CPI R19, 0x77
	BREQ rst_dia_unid0
	RJMP Loop

rst_dia_unid0:
	LDI R23, LOW(tabla << 1)
	RJMP dia_dec

rst_dia_unid:
	LDI R16, 1
	LDI R23, LOW(tabla << 1)
	ADD R23, R16
	RJMP dia_dec
	
dia_dec: 
	INC R18
	MOV ZL, R29
	LPM R19, Z
	CPI R19, 0x3F
	BREQ meses_primeros
	RJMP dias3
	meses_primeros:
	MOV ZL, R28
	LPM R19, Z
	CPI R19, 0x5B
	BREQ dias20
	RJMP dias3
	
	dias20:
	MOV ZL, R18
	LPM R19, Z
	CPI R19, 0x4F
	BREQ rst_dia_dec
	RJMP Loop
	dias3:
	MOV ZL, R18
	LPM R19, Z
	CPI R19, 0x66
	BREQ rst_dia_dec
	RJMP Loop

rst_dia_dec:
	LDI R18, LOW(tabla << 1)
	CPI R22, 3
	BREQ mes_unid
	RJMP Loop

mes_unid:
	CBR R24, 0b0000_0001
	INC R28
	MOV ZL, R29
	LPM R19, Z
	CPI R19, 0x06
	BREQ rst_mes_unid1
	RJMP rst_mes_unid0
rst_mes_unid1:
	MOV ZL, R28
	LPM R19, Z
	CPI R19, 0x4F
	BREQ rst_mes_unid
	RJMP Loop
rst_mes_unid0:
	MOV ZL, R28
	LPM R19, Z
	CPI R19, 0x77
	BREQ rst_mes_unid00
	RJMP Loop
rst_mes_unid:
	LDI R16, 1
	LDI R28, LOW(tabla << 1)
	ADD R28, R16
	RJMP mes_dec
rst_mes_unid00:
	LDI R28, LOW(tabla << 1)
	RJMP mes_dec

mes_dec:  
	INC R29
	MOV ZL, R29
	LPM R19, Z
	CPI R19, 0x5B
	BREQ rst_mes_dec
	RJMP Loop
rst_mes_dec:
	LDI R29, LOW(tabla << 1)
	RJMP Loop

//-----dec dias-----
dec_dia_unid:
	CBR R24, 0b0000_0010
	MOV ZL, R18
	LPM R19, Z
	CPI R19, 0x3F
	BREQ rst_dec_dia_unid1
	RJMP rst_dec_dia_unid0
rst_dec_dia_unid1:
	MOV ZL, R23
	LPM R19, Z
	CPI R19, 0x06
	BREQ rst_dec_dia_unid
	DEC R23
	RJMP Loop
rst_dec_dia_unid0:
	MOV ZL, R23
	LPM R19, Z
	CPI R19, 0x3F
	BREQ rst_dec_dia_unid_normal
	DEC R23
	RJMP Loop
rst_dec_dia_unid_normal:
	LDI R16, 9
	LDI R23, LOW(tabla << 1)
	ADD R23, R16
	RJMP dec_dia_dec
rst_dec_dia_unid:
	MOV ZL, R29
	LPM R19, Z
	CPI R19, 0x3F
	BREQ dec_primeros_meses
	RJMP dec_siguentes_meses
	dec_primeros_meses:
	MOV ZL, R28
	LPM R19, Z
	CPI R19, 0x06 
	BREQ dec_dias31
	CPI R19, 0x4F 
	BREQ dec_dias31
	CPI R19, 0x6D
	BREQ dec_dias31
	CPI R19, 0x07
	BREQ dec_dias31
	CPI R19, 0x7F
	BREQ dec_dias31
	CPI R19, 0x5B
	BREQ dec_dias28
	CPI R19, 0x66
	BREQ dec_dias30
	CPI R19, 0x7D
	BREQ dec_dias30
	CPI R19, 0x6F
	BREQ dec_dias30
	dec_siguentes_meses:
	MOV ZL, R28
	LPM R19, Z
	CPI R19, 0x3F
	BREQ dec_dias31
	CPI R19, 0x5B
	BREQ dec_dias31
	CPI R19, 0x06
	BREQ dec_dias30

dec_dias28:
	LDI R16, 8
	LDI R23, LOW(tabla << 1)
	ADD R23, R16
	RJMP dec_dia_dec
dec_dias30:
	LDI R16, 1
	LDI R23, LOW(tabla << 1)
	ADD R23, R16
	RJMP dec_dia_dec
dec_dias31:
	RJMP dec_dia_dec
	

dec_dia_dec:  
	MOV ZL, R18
	LPM R19, Z
	CPI R19, 0x3F
	BREQ rst_dec_dia_dec
	DEC R18
	RJMP Loop
rst_dec_dia_dec:
	MOV ZL, R29
	LPM R19, Z
	CPI R19, 0x3F
	BREQ rst_dec_dia_dec_primeros
	RJMP rst_dec_dia_dec30
rst_dec_dia_dec_primeros:
	MOV ZL, R28
	LPM R19, Z
	CPI R19, 0x5B
	BREQ rst_dec_dia_dec_feb
	RJMP rst_dec_dia_dec30
rst_dec_dia_dec30:
	LDI R16, 3
	LDI R18, LOW(tabla << 1)
	ADD R18, R16
	RJMP Loop
rst_dec_dia_dec_feb:
	LDI R16, 2
	LDI R18, LOW(tabla << 1)
	ADD R18, R16
	RJMP Loop

dec_mes_unid:
	CBR R24, 0b0000_0010
	MOV ZL, R29
	LPM R19, Z
	CPI R19, 0x3F
	BREQ rst_dec_mes_unid0
	RJMP rst_dec_mes_unid1
rst_dec_mes_unid0:
	MOV ZL, R28
	LPM R19, Z
	CPI R19, 0x06
	BREQ rst_dec_mes_unid00
	DEC R28
	RJMP Loop
rst_dec_mes_unid1:
	MOV ZL, R28
	LPM R19, Z
	CPI R19, 0x3F
	BREQ rst_dec_mes_unid11
	DEC R28
	RJMP Loop
rst_dec_mes_unid00:
	LDI R16, 2
	LDI R28, LOW(tabla << 1)
	ADD R28, R16
	RJMP dec_mes_dec
rst_dec_mes_unid11:
	LDI R16, 9
	LDI R28, LOW(tabla << 1)
	ADD R28, R16
	RJMP dec_mes_dec

dec_mes_dec:  
	MOV ZL, R29
	LPM R19, Z
	CPI R19, 0x3F
	BREQ rst_dec_mes_dec
	DEC R29
	RJMP Loop
rst_dec_mes_dec:
	LDI R16, 1
	LDI R29, LOW(tabla << 1)
	ADD R29, R16
	RJMP Loop

;******************************************************************************

ISR_PCINT1:
	PUSH R16
	IN R16, PINC
	SBRS R16, PC2	;botón 1
	RJMP modo

	SBRS R16, PC5	;botón 4
	RJMP apagar

	SBRS R16, PC3	;botón 2
	RJMP decrementar

	CPI R22, 2
	BREQ inc_dec
	CPI R22, 3
	BREQ inc_dec
	CPI R22, 4
	BREQ inc_dec
	CPI R22, 5
	BREQ inc_dec
	CPI R22, 6
	BREQ inc_dec
	CPI R22, 7
	BREQ inc_dec
	CPI R22, 8
	BREQ inc_dec

	BCLR 1
	POP R16
	RETI

	inc_dec:
	BCLR 1
	SBRS R16, PC4	;botón 3
	RJMP incrementar
	POP R16
	RETI
	
	modo:
	SBR R24, 0b0100_0000
	POP R16
	RETI
	incrementar:
	SBR R24, 0b0000_0001
	POP R16
	RETI
	decrementar:
	SBR R24, 0b0000_0010
	POP R16
	RETI
	apagar:
	SBR R24, 0b0010_0000
	POP R16
	RETI

;******************************************************************************

ISR_TIMER_OVF0:
	PUSH R16
	LDI R16, 251 ; Cargar el valor calculado en donde debería iniciar.
	OUT TCNT0, R16
	POP R16
	LDI R20, 1
	RETI

;******************************************************************************

ISR_TIMER_OVF1:
	PUSH R16
	LDI R16, 0x1B ; valor calculado donde inicia a contar
	//LDI R16, 0xFF ; valor calculado donde inicia a contar
	STS TCNT1H, R16
	LDI R16, 0x1E ; valor calculado donde inicia a contar
	//LDI R16, 0xFF ; valor calculado donde inicia a contar
	STS TCNT1L, R16
	POP R16
	LDI R20, 2
	RETI

;******************************************************************************