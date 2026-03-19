; 03_subroutine_and_loop
; Branching: a call and return (BR.SUB / RETURN) around a counted loop driven by TEST and BRR.Z.
;
	ORG  0x0210
;	.CODE
		IN R0;  02  ; This example tests the branching capabilities of the design.No data dependencies.
		IN R1;  03  ; The values to be loaded into the corresponding register.
		IN R2;  01
		IN R3;  05  ;  End of initialization
		IN R4;  528 ;  0x210 = 528 in decimal
		IN R5;  01 ; for absolute branching
		IN R6;  05 ; r6 is counter for the loop and indicates the number of times the loop is done.
		IN R7;  00
		BR.SUB R4,10 ; Go to the subroutine		
		BRR 0     ; Infinite loop (the end of the program)
		ADD R2, R1, R5  ; Start of the subroutine. It runs for 5 times. R2 <-- R1 + 1
		MUL R1, R0, R2  ; R1 <-- R0 x R2
		SUB R6, R6, R5  ; R6 <-- R6 - 1   The counter for the loop.
		TEST R6         ; Set the z flag for the branch decision
		BRR.z 2     ; If r6 is zero, jump out of the loop. 
		BRR -5		; If not jump to the start of the subroutine.
		RETURN 
	
	END
