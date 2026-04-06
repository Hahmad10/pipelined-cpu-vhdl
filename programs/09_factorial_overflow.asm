; 09_factorial_overflow
; Factorial with overflow detection: BRR.overflow jumps out after a multiply overflows and outputs 0. Runs on the board.
;
; The factorial of IN input number
; OUT(r1)=IN*(IN-1)*(IN-2)*…*2
; This loop should run (N-1) times
; This code tests whether there is a multiply overflow. If there is
; it outputs 0


ORG 0x500
;.DATA
;.CODE
START:

	LOADIMM.upper	0x00
	LOADIMM.lower	0x01 
	MOV r5, r7		; r5 is the decrement value
	MOV r1, r5 		; r1 is the Factorial variable, so it is initialized to 1
	MOV r6, r5 		; r6 is initialized to 1, then it’s shifted to get 2
	SHL r6,1 		; the lowest value to be multiplied by (r6=2)
	IN  r0			; input number
LOOP:
	MUL r1,r1,r0    	; the actual multiplication to find the factorial (IN!)
	;test for overflow
	BRR.overflow OVERFLOW

	SUB r0,r0,r5    	; to move to the lower number (r0-1)
	SUB r4,r0,r6    	; to check if r0 reaches 2
	TEST r4 		; IF negative 
	BRR.N PRINT		; go and output the factorial result
	BRR LOOP		; ElSE, not done yet, go and continue multiplying 
PRINT:
	OUT r1 			; Printout the Factorial
	BRR START		; goto the beginning and loop getting new input 

OVERFLOW:
	LOADIMM.upper	0x00
	LOADIMM.lower	0x00
	OUT 	r7		; Printout the error code 0
	BRR	START		; goto the beginning and loop getting new input 
