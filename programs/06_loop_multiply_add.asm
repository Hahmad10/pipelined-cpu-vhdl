; 06_loop_multiply_add
; Full program: a counted loop of MUL and ADD with immediate loads and branches. Expected output 0x00BF (191).
;
	ORG 0x00
	.CODE
		IN R1    ; 5      
		LOADIMM.LOWER 5
		LOADIMM.UPPER 0
		MOV R2, R7
		LOADIMM.LOWER 2
		LOADIMM.UPPER 0
		MOV R3, R7
		LOADIMM.LOWER 1
		LOADIMM.UPPER 0
		MOV R4, R7
		MUL R1, R1, R3
		ADD R1, R1, R4
		SUB R2, R2, R4
		TEST R2
		BRR.Z 2
		BRR -5
		OUT R1
		BRR 0

	END
