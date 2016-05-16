;**************************************************
; Tapparelle di Emiliano
; source.asm
;
; (c) 2008, Emiliano Macedonio
; http://www.macedonio.it
;**************************************************
PROCESSOR 16F84A
RADIX DEC
INCLUDE "P16F84.INC"
ERRORLEVEL -302
;Setup of PIC configuration flags
;XT oscillator
;Disable watch dog timer
;Enable power up timer
;Disable code protect
__CONFIG 0x3FF1
REL1 EQU 0
REL2 EQU 1
SW1  EQU 4
SW2  EQU 5

ORG 0x0C
Count RES 1  		;Contatore di 1
Cicle RES 1			;Contatore Ciclo Loop
FlagStop RES 1		;Flag di stop processo
	;Reset Vector
	;Start point at CPU reset
ORG 0x00
	;Jump to main body of program.
goto Start

; Interrupt vector
; Start point for every interrupt handler
ORG 0x04
; Interrupt handler
bcf PORTB,REL1

bcf INTCON,RBIF 	;Reset RBIF flag
btfsc PORTB,SW1 	;Pulsante 1 premuto?
Call Switch1GO
btfsc PORTB,SW2 	;Pulsante 2 premuto?
Call Switch2GO
retfie 				;Return to the main body


Start:
		
	bsf STATUS,RP0 ;Commuta sul secondo banco dei registri per accedere ai registri TRISA e TRISB
		;Definizione delle linee di I/O (0=Uscita, 1=Ingresso)
		;Definizione della porta A
	movlw B'00000000'
	movwf TRISA
		;Definizione della porta B
		;Le linee da RB0 a RB3 vengono programmate in uscita per essere collegate ai due relè
		;Le linee da RB4 a RB7 vengono programmate in ingresso per essere collegate ai due pulsanti
	movlw B'11110000'
	movwf TRISB

	;Set to 0 the INTEDG bit on OPTION register
	;to have an interrupt on the falling edge of RB0/INT
	;Assegna il PRESCALER a TMR0 e lo configura a 1:32
	;Vedi subroutine Delay per maggiori chiarimenti
	movlw B'00000100'
	movwf OPTION_REG
	
	bcf STATUS,RP0 	;Commuta sul primo banco dei registri

	bsf INTCON,RBIE ;Enables RBIE interrupt
	bsf INTCON,GIE 	;Enables interrupts
	
	;Spegne tutti i relè
	Call TurnOffRel1
	Call TurnOffRel2
	;setta a 0 il FlagStop
	bcf FlagStop,0

MainLoop
	sleep 			;Power Down Mode
	goto MainLoop

Switch1GO
	Call TurnOnRel1
	Call Delay1Sec			;Primo ritardo per vedere se tutta la corsa o no
	btfss PORTB,SW1 	;Pulsante 1 ancora premuto?
	goto DelayLong		;No - Tutta la corsa
Switch1Running			;Si - Corsa a comando
	Call Delay1Sec
	btfsc PORTB,SW1 	;Pulsante 1 ancora premuto?
	goto Switch1Running	;Si - Continua 
	Call TurnOffRel1	;NO - Spegni Relé
	return

Switch2GO
	Call TurnOnRel2
	Call Delay1Sec		;Primo ritardo per vedere se tutta la corsa o no
	btfss PORTB,SW2 	;Pulsante 2 ancora premuto?
	goto DelayLong		;No - Tutta la corsa
Switch2Running			;Si - Corsa a comando
	Call Delay1Sec
	btfsc PORTB,SW2 	;Pulsante 2 ancora premuto?
	goto Switch2Running	;Si - Continua 
	Call TurnOffRel2	;NO - Spegni Relé
	return

DelayLong
	movlw 30			;30 Cicli = 30 secondi di ritardo per salita o discesa completa tapparelle
	movwf Cicle
DelayLongLoop
	btfss FlagStop,0	;Controllo FlagStop
	Call Delay			;Se FlagStop = 0 1 secondo
	decfsz Cicle,1		;Se FlagStop = 1 Decremento Cicle
	goto DelayLongLoop	;Cicle <> 0
	Call AllOff			;Cicle = 0
	return			

CheckPress
	btfsc PORTB,SW1
	bsf FlagStop,0
	btfsc PORTB,SW2
	bsf FlagStop,0
	return

Delay1Sec
	; Ritardo 1 secondo
	; Inizializza TMR0 per ottenere 250 conteggi prima di arrivare a zero.
	; Il registro TMR0 e' un registro ad 8 bit quindi se viene incrementato
	; nuovamentre quando arriva a 255 ricomincia a contare da zero.
	; Se lo si inizializza a 6 dovra' essere incrementato 256 - 6 = 250 volte
	; prima passare per lo zero.
	movlw 6
	movwf TMR0
	; Il registro Count viene inizializzato a 125 in quanto il suo scopo e' far
	; uscire il loop
	movlw 125
	movwf Count
	;Loop di conteggio
DelayLoop1Sec
	;TMR0 vale 0 ?
	movf TMR0,W
	btfss STATUS,Z
	goto DelayLoop1Sec 	;No, aspetta...
	movlw 6 		;Si, reimposta TMR0 e controlla se
	movwf TMR0 		;e' passato per 125 volte per lo zero
	decfsz Count,1
	goto DelayLoop1Sec
	return

Delay
	; Ritardo 1 secondo
	; Inizializza TMR0 per ottenere 250 conteggi prima di arrivare a zero.
	; Il registro TMR0 e' un registro ad 8 bit quindi se viene incrementato
	; nuovamentre quando arriva a 255 ricomincia a contare da zero.
	; Se lo si inizializza a 6 dovra' essere incrementato 256 - 6 = 250 volte
	; prima passare per lo zero.
	movlw 6
	movwf TMR0
	; Il registro Count viene inizializzato a 125 in quanto il suo scopo e' far
	; uscire il loop
	movlw 125
	movwf Count
	;Loop di conteggio
DelayLoop
	;check pressione tasto 
	Call CheckPress
	btfsc FlagStop,0
	return
	;TMR0 vale 0 ?
	movf TMR0,W
	btfss STATUS,Z
	goto DelayLoop 	;No, aspetta...
	movlw 6 		;Si, reimposta TMR0 e controlla se
	movwf TMR0 		;e' passato per 125 volte per lo zero
	decfsz Count,1
	goto DelayLoop
	return

AllOff
	;Spegne il REL1
	bcf PORTB,REL1
	;Spegne il REL2
	bcf PORTB,REL2
	;azzera FlagStop
	bcf FlagStop,0
	Call Delay1Sec
	retfie
	goto MainLoop

TurnOnRel1
	;Accende il REL1
	bsf PORTB,REL1
	return

TurnOffRel1
	;Spegne il REL1
	bcf PORTB,REL1
	return

TurnOnRel2
	;Accende il REL2
	bsf PORTB,REL2
	return

TurnOffRel2
	;Spegne il REL2
	bcf PORTB,REL2
	return

END