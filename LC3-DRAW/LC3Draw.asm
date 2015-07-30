; LC3 Draw is a library that consists of functions to "draw" using the console.
; LC3 Draw utilizes a screen data type that is 79x23 characters. This is known as the Display
; It's addressable from (0-78)x(0-22). The last column is unused due to the nature of the console scroll.
; Each "Pixel" consists of a "compact character" where two characters are stored in a 16 bit word
; TRAP x24 (PUTSP) subroutine will draw what's in the Display. Display is stored at xE000
; LC3 Draw will utilize LC3-Extended in order to take advantage of functions such as shifting and arithmetic
	.ORIG	x3000		;
	AND	R0,R0,#0		;
	ST	R0,X		; x = 0
	ST	R0,Y		; y = 0
LOOPER
	JSR	Render		;
	JSR	Clear		;
	GETC			;
CL
	LD	R1,LEFT		;
	ADD	R1,R0,R1		;
	BRz	M_L		;
CU
	LD	R1,UP		;
	ADD	R1,R0,R1		;
	BRz	M_U		;
CR
	LD	R1,RIGHT		;
	ADD	R1,R0,R1		;
	BRz	M_R		;
CD
	LD	R1,DOWN		;
	ADD	R1,R0,R1		;
	BRz	M_D		;
	CONT
	LD	R0,PIC		;
	LD	R1,X		;
	LD	R2,Y		;
	JSR	DrawPic		;
	BRnzp	LOOPER		;
LEFT	.FILL	x-61		;
UP	.FILL	x-77		;
RIGHT	.FILL	x-64		;
DOWN	.FILL	x-73		;
PIC	.FILL	xD000		;
X	.BLKW	1		;
Y	.BLKW	1		;

M_L
	LD	R0,X		;
	ADD	R0,R0,#-1		; x--
	ST	R0,X		;
	BRnzp	CU		;
M_U
	LD	R0,Y		;
	ADD	R0,R0,#-1		; y--
	ST	R0,Y		;
	BRnzp	CR		;
M_R
	LD	R0,X		;
	ADD	R0,R0,#1		; x++
	ST	R0,X		;
	BRnzp	CR		;
M_D
	LD	R0,Y		;
	ADD	R0,R0,#1		; y++
	ST	R0,Y		;
	BRnzp	CONT		;
;;;;
; Subroutine Render
; Input: None
; Output: None
; Will use TRAP x24 PUTSP to print
;;;;
Render
	ST	R0,REN_SR0		;
	ST	R7,REN_SR7		;
	LD	R0,REN_DIS		;
	PUTSP			;
	LD	R0,REN_SR0		;
	LD	R7,REN_SR7		;
	RET
REN_DIS	.FILL	xE000		;
REN_SR0	.BLKW	1		;
REN_SR7	.BLKW	1		;

;;;;
; Subroutine SetPixel
; Input: R0=Char,R1=X (0-78),R2=Y (0-22)
; Output:None
; Note: Top left corner is (0,0). Max ASCII/Extended ASCII value is xFF
; It does take advantage of the two chars per word
;;;;
SetPixel
	ST	R0,SP_SR0		;
	ST	R1,SP_SR1		;
	ST	R2,SP_SR2		;
	ST	R3,SP_SR3		;
	ST	R4,SP_SR4		;
	ST	R7,SP_SR7		;
				; Bounds checking
	ADD	R1,R1,#0		; Are X and Y below 0?
	BRn	SP_END		;
	ADD	R2,R2,#0		;
	BRn	SP_END		;
	LD	R4,SP_N78		;
	ADD	R4,R1,R4		; Is X > 78?
	BRp	SP_END		;
	LD	R4,SP_N22		;
	ADD	R4,R2,R4		; Is Y > 22?
	BRp	SP_END
	LD	R3,SP_DISPLAY	; R3 has the base address of the buffer
	ADD	R2,R2,#0		; Get CC for R2 (Y)
SP_LOOP
	BRz	SP_CONT		; If zero, no need to go down rows
	LD	R4,SP_NCOLS		; R3 has 40
	ADD	R3,R3,R4		; Add 40 to the address
	ADD	R2,R2,#-1		; Decrement R2
	BRnzp	SP_LOOP
SP_CONT
	AND	R4,R4,#0		; Clear R4 for output char
	ADD	R0,R1,#0		; Move X into R0
	AND	R1,R1,#0		;
	ADD	R1,R1,#1		; 1 right shift
	TRAP	x29		; LSR to divide by 2 ---------------------; change according to updates
	ADD	R3,R3,R0		; Add the X position to the address
	LD	R0,SP_SR1		;
	AND	R0,R0,#1		; Get bit 0 of X
	BRz	SP_EVEN		;
	BRp	SP_ODD		;
SP_EVEN				; Zero bit
	LDR	R0,R3,0		; Load the word at that address
	LD	R1,SP_MSM		; Mask the upper bits
	AND	R1,R0,R1		;
	LD	R0,SP_SR0		; R0 has the char
	ADD	R1,R0,R1		;
	STR	R1,R3,0		;
	BRnzp	SP_END		;
SP_ODD				; One bit
	LDR	R0,R3,0		; Load word at that address
	LD	R1,SP_LSM		; Mask the lower bits
	AND	R1,R0,R1		;
	LD	R0,SP_SR0		; R0 has the char
	ADD	R4,R1,#0		; R4 has the output word
	AND	R1,R1,#0		; R0 has char, R1 has # of shifts
	ADD	R1,R1,#8		;
	TRAP	x28		; 4 left shifts
	ADD	R4,R0,R4		; Update the output char
	STR	R4,R3,0		;
	BRnzp	SP_END		;
SP_END
				;
	LD	R0,SP_SR0		;
	LD	R1,SP_SR1		;
	LD	R2,SP_SR2		;
	LD	R3,SP_SR3		;
	LD	R4,SP_SR4		;
	LD	R7,SP_SR7		;
	RET			;
SP_DISPLAY	.FILL	xE000		;
SP_NCOLS	.FILL	40		;
SP_MSM	.FILL	xFF00		; Keep upper chars
SP_LSM	.FILL	x00FF		; Keep lower chars
SP_N22	.FILL	-22		; For bounds checking
SP_N78	.FILL	-78		;
SP_SR0	.BLKW	1		;
SP_SR1	.BLKW	1		;
SP_SR2	.BLKW	1		;
SP_SR3	.BLKW	1		;
SP_SR4	.BLKW	1		;
SP_SR7	.BLKW	1		;

;;;;
; Subroutine Clear
; Inputs: None
; Outputs: None
; Sets the display to a completely blank state
;;;;
Clear
	ST	R0,CL_SR0		;
	ST	R1,CL_SR1		;
	ST	R2,CL_SR2		;
	ST	R3,CL_SR3		;
	ST	R4,CL_SR4		;
	
	LD	R0,CL_COLS2		;
	LD	R1,CL_ROWS2		;
	LD	R3,CL_DISPLAY	;
	ADD	R3,R3,#-1		;
CL_BULK	
	ADD	R3,R3,#1		;
	ADD	R0,R0,#0		;
	BRz	CL_ROWEND		;
	LD	R4,CL_BL		;
	STR	R4,R3,0		;
	ADD	R0,R0,#-1		;
	BRnzp	CL_BULK		;
CL_ROWEND	
	ADD	R1,R1,#0		;
	BRp	CL_NOTLAST		; If it's not zero, don't do row ending char
	LD	R4,CL_LAST		;
	STR	R4,R3,0		;
	BRnzp	CL_END		;
CL_NOTLAST
	LD	R4,CL_RWEND		;
	STR	R4,R3,0		;
	LD	R0,CL_COLS2		;
	ADD	R1,R1,#-1		;
	BRnzp	CL_BULK		;
CL_END
	LD	R0,CL_SR0		;
	LD	R1,CL_SR1		;
	LD	R2,CL_SR2		;
	LD	R3,CL_SR3		;
	LD	R4,CL_SR4		;
	RET			;
CL_DISPLAY	.FILL	xE000		;
CL_COLS2	.FILL	39		; Length of bulk
CL_ROWS2	.FILL	22		;
CL_BL	.FILL	x2020		; Bulk of row
CL_RWEND	.FILL	x0A20		; End of row
CL_LAST	.FILL	x0020		; Last character
CL_SR0	.BLKW	1		; 
CL_SR1	.BLKW	1		; 
CL_SR2	.BLKW	1		; 
CL_SR3	.BLKW	1		; 
CL_SR4	.BLKW	1		; 

;;;;;
; Subroutine DrawLine
; Input : R0 = char; R1,R2 = x0,y0; R3,R4 = x1,y1
; Output: None
; Code adapted from the LCD_functions.h for the Nokia 5100 LCD by Sparkfun
;;;;;
DrawLine
	ST	R0,DL_SR0		;
	ST	R1,DL_SR1		;
	ST	R2,DL_SR2		;
	ST	R3,DL_SR3		;
	ST	R4,DL_SR4		;
	ST	R7,DL_SR7		;
	; Variable initialization	;
	ST	R1,DL_X0		; Initialize coords
	ST	R2,DL_Y0		;
	ST	R3,DL_X1		;
	ST	R4,DL_Y1		;
	
	NOT	R1,R1		; R1 = -x0
	ADD	R1,R1,#1		;
	ADD	R1,R1,R3		; R1 = x1 - x0 = dx
	ST	R1,DL_DX		; DL_DX initialized
	NOT	R2,R2		; R2 = -x0
	ADD	R2,R2,#1		;
	ADD	R2,R2,R4		; R2 = x1 - x0 = dy
	ST	R2,DL_DY		; DL_DY initialized
				; R1 = dx, R2 = dy
	; Logic start		;
DL_DYC				; DY check
	ADD	R2,R2,#0		; Get CC for R2 == dy
	BRn	DL_DYLZ		; If dy negative
	BRzp	DL_DYEL		; else
DL_DXC				; DX check
	ADD	R1,R1,#0		; CC for R1 == dx
	BRn	DL_DXLZ		; If dx neg
	BRzp	DL_DXEL		; else
DL_L1	
	LD	R2,DL_DY
	ADD	R2,R2,R2		; Leftshift dy; dy *= 2
	ST	R2,DL_DY
	LD	R1,DL_DX
	ADD	R1,R1,R1		; Leftshift dx; dx *= 2
	ST	R1,DL_DX
	LD	R0,DL_SR0		; Load inputs for drawing
	LD	R1,DL_X0		;
	LD	R2,DL_Y0		;
	JSR	SetPixel		; Draw first pixel
	
	LD	R1,DL_DX		; R1 = dx
	LD	R2,DL_DY		; R2 = dy
	NOT	R2,R2		; R2 = -dy
	ADD	R2,R2,#1		;
	ADD	R1,R1,R2		; R1 = dx - dy
	BRp	DL_DXGTDY		; dx greater than dy
	BRnz	DL_DXDYEL		; else
DL_END	; Restore inputs		;
	LD	R0,DL_SR0		;
	LD	R1,DL_SR1		;
	LD	R2,DL_SR2		;
	LD	R3,DL_SR3		;
	LD	R4,DL_SR4		;
	LD	R7,DL_SR7		;
	RET
	; Conditional code branches	;
DL_DYLZ
	; R2 has dy already
	NOT	R2,R2		; Negate R2
	ADD	R2,R2,#1		;
	ST	R2,DL_DY		; dy = -dy
	AND	R4,R4,#0		;
	ADD	R4,R4,#-1		;
	ST	R4,DL_STEPY		; stepy init
	BRnzp	DL_DXC		;
DL_DYEL
	AND	R4,R4,#0		;
	ADD	R4,R4,#1		;
	ST	R4,DL_STEPY		; stepy init
	BRnzp	DL_DXC		;
DL_DXLZ
	; R1 has dx already
	NOT	R1,R1		; Negate R1
	ADD	R1,R1,#1		; 
	ST	R1,DL_DX		; dx = -dx
	AND	R3,R3,#0		;
	ADD	R3,R3,#-1		;
	ST	R3,DL_STEPX		; stepx init
	BRnzp	DL_L1		;
DL_DXEL
	AND	R3,R3,#0		;
	ADD	R3,R3,#1		;
	ST	R3,DL_STEPX		; stepx init
	BRnzp	DL_L1		;
DL_DXGTDY
	LD	R0,DL_DX		;
	LD	R1,DL_1		;
	TRAP	x29		; Arithmetic right shift ---------(bugged, using lsr for now)
	NOT	R4,R0		; Start negate of dx>>1, put in R4
	ADD	R4,R4,#1		; R4 = -dx>>1
	LD	R3,DL_DY		; R3 = dy
	ADD	R3,R3,R4		; R3 = dy - dx>>1
	ST	R3,DL_FRAC		; fraction init
	DL_DXGTDYL
				; check for loop ending
	LD	R1,DL_X0		; R1 = x0
	LD	R2,DL_X1		; R2 = x1
	NOT	R2,R2		; R2 = -x1
	ADD	R2,R2,#1		;
	ADD	R2,R1,R2		; R2 = x0 - x1
	BRz	DL_END		; While x0 - x1 != 0 continue
	LD	R1,DL_FRAC		; R1 = fraction
	BRzp	DL_DXGTDYF		; If frac >= 0, execute code there
	DL_DXGTDYLC
	LD	R1,DL_X0		; R1 = x0
	LD	R2,DL_STEPX		; R2 = stepx
	ADD	R1,R1,R2		; R1 = x0 + stepx
	ST	R1,DL_X0		; Store the new x0
	LD	R1,DL_FRAC		; R1 = fraction
	LD	R2,DL_DY		; R2 = dy
	ADD	R1,R1,R2		; R1 = fraction + dy
	ST	R1,DL_FRAC		; fraction += dy
	LD	R0,DL_SR0		; Load SetPixel input
	LD	R1,DL_X0		;
	LD	R2,DL_Y0		;
	JSR	SetPixel		;
	BRnzp	DL_DXGTDYL		;
DL_DXDYEL
	LD	R0,DL_DY		;
	LD	R1,DL_1		;
	TRAP	x29		; Arithmetic right shift ----------- (bugged, using lsr for now)
	NOT	R4,R0		; Start negate of dy>>1, put in R4
	ADD	R4,R4,#1		; R4 = -dy>>1
	LD	R3,DL_DX		; R3 = dx
	ADD	R3,R3,R4		; R3 = dx - dy>>1
	ST	R3,DL_FRAC		; fraction init
	DL_DXDYELL
				; check for loop ending
	LD	R1,DL_Y0		; R1 = y0
	LD	R2,DL_Y1		; R2 = y1
	NOT	R2,R2		; R2 = -y1
	ADD	R2,R2,#1		;
	ADD	R2,R1,R2		; R2 = y0 - y1
	BRz	DL_END		; While y0 - y1 != 0 continue
	LD	R1,DL_FRAC		; R1 = fraction
	BRzp	DL_DXDYELF		; If frac >= 0, execute code there
	DL_DXDYELC
	LD	R1,DL_Y0		; R1 = y0
	LD	R2,DL_STEPY		; R2 = stepy
	ADD	R1,R1,R2		; R1 = y0 + stepy
	ST	R1,DL_Y0		; Store the new y0
	LD	R1,DL_FRAC		; R1 = fraction
	LD	R2,DL_DX		; R2 = dx
	ADD	R1,R1,R2		; R1 = fraction + dx
	ST	R1,DL_FRAC		; fraction += dx
	LD	R0,DL_SR0		; Load SetPixel input
	LD	R1,DL_X0		;
	LD	R2,DL_Y0		;
	JSR	SetPixel		;
	BRnzp	DL_DXDYELL		;
DL_DXGTDYF
	LD	R1,DL_Y0		; R1 = y0
	LD	R2,DL_STEPY		; R2 = stepy
	ADD	R1,R1,R2		; R1 = y0 + stepy
	ST	R1,DL_Y0		; Store new y0
	LD	R1,DL_FRAC		; R1 = fraction
	LD	R2,DL_DX		; R2 = dx
	NOT	R2,R2		; R2 = -dx
	ADD	R2,R2,#1		;
	ADD	R1,R1,R2		; R1 = fraction - dx
	ST	R1,DL_FRAC		; Store new fraction (fraction -= dx)
	BRnzp	DL_DXGTDYLC		;
DL_DXDYELF
	LD	R1,DL_X0		; R1 = x0
	LD	R2,DL_STEPX		; R2 = stepx
	ADD	R1,R1,R2		; R1 = x0 + stepx
	ST	R1,DL_X0		; Store new x0
	LD	R1,DL_FRAC		; R1 = fraction
	LD	R2,DL_DY		; R2 = dy
	NOT	R2,R2		; R2 = -dy
	ADD	R2,R2,#1		;
	ADD	R1,R1,R2		; R1 = fraction - dy
	ST	R1,DL_FRAC		; Store new fraction (fraction -= dy)
	BRnzp	DL_DXDYELC
DL_1	.FILL	1		;
DL_SR0	.BLKW	1		;
DL_SR1	.BLKW	1		;
DL_SR2	.BLKW	1		;
DL_SR3	.BLKW	1		;
DL_SR4	.BLKW	1		;
DL_SR7	.BLKW	1		;
DL_X0	.BLKW	1		; SR1
DL_Y0	.BLKW	1		; SR2
DL_X1	.BLKW	1		; SR3
DL_Y1	.BLKW	1		; SR4
DL_DX	.BLKW	1		; dx
DL_DY	.BLKW	1		; dy
DL_STEPX	.BLKW	1		; stepx
DL_STEPY	.BLKW	1		; stepy
DL_FRAC	.BLKW	1		; fraction

;;;;;
; Subroutine DrawPic
; Input : R0 is a pointer to the Pic ; R1,R2 = x,y
; Output: None
;;;;;
; R0 is the pointer loc VITAL DON'T USE
; This works a lot like the PC. Upon loading the value, increment the pointer
DrawPic
	ST	R0,DP_SR0		;
	ST	R1,DP_SR1		;
	ST	R2,DP_SR2		;
	ST	R3,DP_SR3		;
	ST	R7,DP_SR7		;
DP_INIT
	ST	R1,DP_X		; x = R1
	ST	R2,DP_Y		; y = R2
	LDR	R1,R0,0		; R1 = width
	LDR	R2,R0,1		; R2 = height
	ST	R1,DP_W		; w = width
	ST	R2,DP_H		; h = height
	ST	R1,DP_HOR		; hor = width
	ST	R2,DP_VER		; ver = height
	AND	R3,R3,#0		; Clear R3
	ST	R3,DP_POS		; pos = 0
	ADD	R0,R0,#2		; Move the pointer to the first memloc of the data
	ST	R0,DP_PTR		; ptr = memloc+2
DP_SPECIAL	LD	R0,DP_PTR		; Check for special cases
	LDR	R1,R0,0		;
	ST	R1,DP_CUR		; cur = current value
	LD	R2,DP_CPYRW		;
	ADD	R2,R1,R2		; Compare to Copy Row (0100)
	BRz	DP_COPYROW		;
	LD	R2,DP_CPYCA		;
	ADD	R2,R1,R2		; Compare to Copy Chars (0101)
	BRz	DP_COPYCHAR		;
	LD	R2,DP_TERM		;
	ADD	R2,R1,R2		; Compare to Terminate (0303)
	BRz	DP_END	;
DP_CHARC				; Check on a char by char basis
	LD	R1,DP_POS		;
	BRz	DP_LEFT		;
	BRp	DP_RGHT		;
DP_ANAL
	LD	R1,DP_CUR		;
	BRz	DP_NEXT		; A 00 means no printing
	LD	R2,DP_NL		; R2 = x-0A
	ADD	R2,R1,R2		; Compare value to x-0A
	BRz	DP_NEWLINE		;
				; Else, place the character in the buffer
	ST	R0,DP_PTR		; Store pointer
	LD	R0,DP_CUR		; R0 = cur
	LD	R1,DP_X		; R1 = x
	LD	R2,DP_Y		; R2 = y
	JSR	SetPixel		; SetPixel(cur,x,y)
	LD	R0,DP_PTR		; Restore pointer
DP_NEXT
	LD	R0,DP_POS		;
	BRp	DP_SKPTR		; If pos (having been changed) is positive, next char is in same loc
	LD	R0,DP_PTR		;
	ADD	R0,R0,#1		; ptr ++
	ST	R0,DP_PTR		;
	DP_SKPTR
	LD	R1,DP_X		;
	ADD	R1,R1,#1		; Increment X
	ST	R1,DP_X		;
	LD	R1,DP_HOR		;
	ADD	R1,R1,#-1		; Decrement horizontal
	ST	R1,DP_HOR		; hor --
	LD	R1,DP_HOR		; R1 = hor
	LD	R2,DP_VER		; R2 = ver
	ADD	R1,R1,#0		; Update CC for hor
	BRp	DP_SKIPHOR		; If hor <= 0
				; This code shifts down to the next row: X= 0, Y--
	ADD	R2,R2,#-1		; decrement R2 = ver
	LD	R1,DP_W		; R1 = w
	ST	R1,DP_HOR		;
	ST	R2,DP_VER		;
	LD	R1,DP_SR1		; Load original X
	ST	R1,DP_X		; x = SR1
	LD	R1,DP_Y		;
	ADD	R1,R1,#1		; Increment Y
	ST	R1,DP_Y		; y++
	LD	R3,DP_CRE		; R3 = copy row enable
	BRp	DP_COPYROWC		; If it's true, branch to the ending part of copyrow
	LD	R1,DP_POS		;
	BRz	DP_SKIPHOR		; If it's already set for the leftmost bits, skip
	LD	R1,DP_PTR		; Set the pointer to the next loc
	ADD	R1,R1,#1		;
	ST	R1,DP_PTR		; ptr++
	AND	R1,R1,#0		;
	ST	R1,DP_POS		; pos = 0
	DP_SKIPHOR
	LD	R1,DP_CCE		; R1 = copy char enable
	BRnz	DP_SKIPCC		; If CCE > 0
	LD	R1,DP_CCC		;
	ADD	R1,R1,#-1		;
	BRnz	DP_COPYCHARC	; If CCC is <= zero, end the Copy Char
	ST	R1,DP_CCC		; CCC --
	DP_SKIPCC
	ADD	R2,R2,#0		; update CC for ver
	BRnz	DP_END		; If ver <= 0, it's done
	BRnzp	DP_SPECIAL		;
DP_END
	LD	R0,DP_SR0		;
	LD	R1,DP_SR1		;
	LD	R2,DP_SR2		;
	LD	R3,DP_SR3		;
	LD	R7,DP_SR7		;
	RET
	; Special cases
DP_LEFT
	ST	R0,DP_PTR		; Store the pointer
	LD	R1,DP_CUR		;
	LD	R2,DP_MASKL		;
	AND	R0,R1,R2		; Mask for the MSBs
	AND	R1,R1,#0		;
	ADD	R1,R1,#8		;
	TRAP	x2A		; Left circular shift
	ST	R0,DP_CUR		;
	LD	R0,DP_PTR		; Restore the pointer
	LD	R1,DP_POS		;
	ADD	R1,R1,#1		; pos was 0, now add 1
	ST	R1,DP_POS		;
	BRnzp	DP_ANAL		; har har har don't laugh. such is consistency
DP_RGHT
	LD	R1,DP_CUR		;
	LD	R2,DP_MASKR		; R2 = Maskright
	AND	R1,R1,R2		; Mask the rightmost values
	ST	R1,DP_CUR		; Store the current value
	LD	R1,DP_POS		; R1 = pos
	AND	R1,R1,#0		; pos was 1, now is 0
	ST	R1,DP_POS		; pos = 0
	BRnzp	DP_ANAL		;
DP_NEWLINE
	LD	R1,DP_W		; R1 = w
	ST	R1,DP_HOR		; hor = w
	LD	R2,DP_VER		; R2 = ver
	ADD	R2,R2,#-1		; R2 = ver -1
	BRnz	DP_END		; If R2 == ver <= 0, end
	ST	R2,DP_VER		; ver --
	LD	R1,DP_SR1		; R1 = x0
	ST	R1,DP_X		; x = x0
	LD	R1,DP_Y		; y++
	ADD	R1,R1,#1		;
	ST	R1,DP_Y		;
	LD	R1,DP_POS		; If pos is 1, increment the pointer and clear pos
	BRnz	DP_SPECIAL		;
	AND	R1,R1,#0		;
	ST	R1,DP_POS		; pos = 0
	LD	R1,DP_PTR		;
	ADD	R1,R1,#1		;
	ST	R1,DP_PTR		; ptr ++
	BRnzp	DP_SPECIAL		;
DP_COPYROW
	AND	R1,R1,#0		;
	ADD	R1,R1,#1		;
	ST	R1,DP_CRE		; Copy Row enable = 1
	LD	R0,DP_PTR		;
	LDR	R1,R0,1		; R1 = offset
	ADD	R2,R0,#2		; R2 points to next relevant memloc
	ST	R2,DP_RETURN	; Store return address from R2
	ADD	R0,R0,R1		; Add CopyRow memloc to offset
	ST	R0,DP_PTR		; The pointer is now at the target location
	BRnzp	DP_SPECIAL		;
	DP_COPYROWC
	AND	R1,R1,#0		;
	ST	R1,DP_CRE		; Copy Row enable = 0
	LD	R0,DP_RETURN	; Load the return address
	ST	R0,DP_PTR		; Update the pointer to the return address
	BRnzp	DP_SPECIAL		;
DP_COPYCHAR
	AND	R1,R1,#0		;
	ADD	R1,R1,#1		;
	ST	R1,DP_CCE		; Copy Char Enable = 1
	LD	R0,DP_PTR		;
	ADD	R1,R0,#4		; Update pointer to next relevant memloc
	ST	R1,DP_RETURN	; Store it in the return address
	LDR	R1,R0,1		; R1 = offset
	ADD	R2,R0,R1		; R2 = PTR + offset
	ST	R2,DP_PTR		; Store the new pointer
	LDR	R1,R0,2		; R1 = newpos
	ST	R1,DP_POS		; Store the char position
	LDR	R1,R0,3		; R1 = number of chars to display
	ST	R1,DP_CCC		;
	BRnzp	DP_SPECIAL		;
	DP_COPYCHARC
	AND	R1,R1,#0		;
	ST	R1,DP_CCE		; Copy Char enable = 0
	LD	R0,DP_RETURN	; Load the return address
	ST	R0,DP_PTR		; Update the pointer to the return address
	BRnzp	DP_SPECIAL		;
DP_CPYRW	.FILL	x-0100		;
DP_CPYCA	.FILL	x-0101		;
DP_TERM	.FILL	x-0303		;
DP_NL	.FILL	x-0A		;
DP_MASKL	.FILL	xFF00		;
DP_MASKR	.FILL	x00FF		;
DP_PTR	.BLKW	1		;
DP_X	.BLKW	1		;
DP_Y	.BLKW	1		;
DP_W	.BLKW	1		;
DP_H	.BLKW	1		;
DP_HOR	.BLKW	1		;
DP_VER	.BLKW	1		;
DP_CUR	.BLKW	1		;
DP_POS	.BLKW	1		; This determines if it's the first (0) position or second (1) position
DP_RETURN	.BLKW	1		;
DP_CRE	.BLKW	1		; Copy Row Enable
DP_CCE	.BLKW	1		; Copy Char Enable
DP_CCC	.BLKW	1		; Copy Char Count
DP_SR0	.BLKW	1		;
DP_SR1	.BLKW	1		;
DP_SR2	.BLKW	1		;
DP_SR3	.BLKW	1		;
DP_SR7	.BLKW	1		;
	.END