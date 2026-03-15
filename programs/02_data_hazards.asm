; 02_data_hazards
; Back-to-back read-after-write dependencies. Checks that forwarding delivers the right values without NOPs.
;
	ORG  0x0210
;	.CODE
		IN R0 ; 02  ; This example tests how data dependencies are handled
		IN R1 ; 03  ; The values to be loaded into the corresponding resgister.
		IN R2 ; 01
		IN R3 ; 05  ;  End of initialization
		ADD R1, R1, R2
		SUB R2, R1, R0
		SUB R1, R3, R2

	END
