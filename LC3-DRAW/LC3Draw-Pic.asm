; This is an example of the "Pic" data type for LC3Draw
; It serves as a picture format
; The LC3Draw API addresses only 79x23. Bitmaps can be larger then be offset with coordinates for rendering
; When .FILLing your data, the MSB will be part of the leftmost character. The LSB will be part of the 
; right most character. This is done mainly for the sake of human convenience when creating bitmaps
; E.g. x4142 will result in AB, not BA
; The program that loads the bitmaps will ignore the last character if the width is odd. Best practice
; is to put a 00 there.

;---------------;
; Special Fills ;
;---------------;

;;;;
; 00 indicates transparency. No change

;;;;
; 0A is new line. It forces the program to a new line, resetting the horizontal counter
; and decrementing the vertical counter. It will set the X to X0 and Y++

;;;;
; x0100 is Copy Row
; x???? is the offset to the location of the row

;;;;
; x0101 is Copy Characters
; x???? is the offset to the memory location of start position
; 0/1 decides if the first character (0,MSB) or second character (1,MSB) starts
; ? decides how many characters will be printed

;;;;
; x0303 is Terminate
; This will end the Pic file. Best practice is to put it even though you have enough characters to print
; This can be used to end the file prematurely without completely filling out the entire last row
	.ORIG	xD000		;
;-----------------------------------------------;
; Name  : Hello World
; Width : 31 
; Height: 5
WIDTH	.FILL	31		;
HEIGHT	.FILL	5		;
ROW1	.FILL	x4820
	.FILL	x2048
	.FILL	x2020
	.FILL	x4545
	.FILL	x4545
	.FILL	x2020
	.FILL	x4C20
	.FILL	x2020
	.FILL	x2020
	.FILL	x4C20
	.FILL	x2020
	.FILL	x2020
	.FILL	x4F4F
	.FILL	x4F4F
	.FILL	x2020
	.FILL	x5100
ROW2	.FILL	x4820
	.FILL	x2048
	.FILL	x2020
	.FILL	x4520
	.FILL	x2020
	.FILL	x2020
	.FILL	x4C20
	.FILL	x2020
	.FILL	x2020
	.FILL	x4C20
	.FILL	x2020
	.FILL	x2020
	.FILL	x4F20
	.FILL	x204F
	.FILL	x2020
	.FILL	x5100
ROW3	.FILL	x4848
	.FILL	x4848
	.FILL	x2020
	.FILL	x4545
	.FILL	x4545
	.FILL	x2020
	.FILL	x4C20
	.FILL	x2020
	.FILL	x2020
	.FILL	x4C20
	.FILL	x2020
	.FILL	x2020
	.FILL	x4F20
	.FILL	x204F
	.FILL	x2020
	.FILL	x5100
ROW4	.FILL	x0101		; [Compression: Copy Characters
	.FILL	-32		; [This is an offset value to take bits from
	.FILL	0		; [First character (0) or second character (1)
	.FILL	30		; [This is how many chars to print
	.FILL	x2000
ROW5	;.FILL	x0100		; [Compression: Copy Row
	;.FILL	-52		; [Offset to address of row: this goes to row 1
	.FILL	x4820
	.FILL	x2048
	.FILL	x2020
	.FILL	x4545
	.FILL	x4545
	.FILL	x2020
	.FILL	x4C4C
	.FILL	x4C4C
	.FILL	x2020
	.FILL	x4C4C
	.FILL	x4C4C
	.FILL	x2020
	.FILL	x4F4F
	.FILL	x4F4F
	.FILL	x2020
	.FILL	x5100
	
	
	.FILL	x0303		; Customary 0303 to end bitmap. The algorithm should stop 
				; right before this; have it here just in case. It can also
				; serve to force the drawing to stop
;-----------------------------------------------;
	.END