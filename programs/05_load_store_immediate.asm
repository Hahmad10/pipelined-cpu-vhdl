; 05_load_store_immediate
; LOADIMM upper/lower byte loads, MOV, and a STORE then LOAD round-trip through data memory.
;
	ORG 0x0210
;.CODE
		LOADIMM.LOWER 15
		LOADIMM.UPPER 5
		MOV R1, R7
		LOADIMM.LOWER 0
		LOADIMM.UPPER 6
		MOV R2, R7
		STORE R2, R1
		LOAD R3, R2
	
	END
