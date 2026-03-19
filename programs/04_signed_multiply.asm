; 04_signed_multiply
; Signed multiplication with a negative operand.
;
	ORG 0x0210
;	.CODE

		IN R0 ; -2  ; This example tests how fast a multiplication operation is performed.
		IN R1 ; 03  ; The values to be loaded into the corresponding register.
		IN R2 ; 01
		IN R3 ; 05  ;  End of initialization
		MUL R6, R0, R3
		BRR 0

	END