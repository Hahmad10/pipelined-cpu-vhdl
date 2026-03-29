; 07_loop_nand_shift
; Full program: a counted loop of NAND and SHL. Expected output 0xFFFA (-6).
;
	ORG 0x08
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
		NAND R1, R1, R3
		SHL R1 1
		SUB R2, R2, R4
		TEST R2
		BRR.Z 2
		BRR -5
		OUT R1
		BRR 0
	
	END
