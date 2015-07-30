.ORIG   x1000       ;

;-----------------------------;
;------------Logic------------;
;-----------------------------;
; These two span x1000:x1015

;;;;TRAP x26
; Subroutine OR: 
; Input: R0=A, R1=B
; Output: R0 = A|B
OR  ;-----------------------------------;x1000
                    ;              |R0         |R1         |
                    ;              |___________|___________|
    NOT R0,R0       ;              |A'         |B          |
    NOT R1,R1       ;              |A'         |B'         |
    AND R0,R0,R1    ;              |A' & B'    |B'         |
    NOT R0,R0       ;              |(A' & B')' |B'         |
    NOT R1,R1       ;R1 restore => |(A' & B')' |B          |
    RET         ;x1005
    ;-----------------------------------;x1005

;;;;TRAP x27
; Subroutine XOR: 
; Input: R0 = X, R1 = Y
; Output: R0 = X^Y
XOR ;-----------------------------------;x1006
    ST  R1,XOR_SVR1     ;
    ST  R2,XOR_SVR2     ;
    ST  R7,XOR_SVR7     ; Calls OR
                        ;           |X          |Y          |?          |
                        ;           |R0         |R1         |R2         |
                        ;           |___________|___________|___________|
    ADD R2,R0,#0        ; R2 = X    |X          |Y          |X          |
    NOT R0,R0           ; R0 = X'   |X'         |Y          |X          |
    AND R0,R0,R1        ; R0 = X'&Y |X' & Y     |Y          |X          |
    NOT R1,R1           ; R1 = Y'   |X' & Y     |Y'         |X          |
    AND R1,R1,R2        ; R1 = Y'&X |X' & Y     |Y' & X     |X          |
    JSR OR              ; R0 = X^Y  |X ^ Y      |Y' & X     |X          |
                        ;   
    LD  R1,XOR_SVR1     ;           |X ^ Y      |Y          |X          |
    LD  R2,XOR_SVR2     ;           |X ^ Y      |Y          |?          |
    LD  R7,XOR_SVR7     ;
    RET                 ;x1012
XOR_SVR1    .BLKW   1   ;
XOR_SVR2    .BLKW   1   ;
XOR_SVR7    .BLKW   1   ;
    ;-----------------------------------;x1015



;-----------------------------;
;-----------Shifts------------;
;-----------------------------;
; These span from x1016:x1090

;;;; TRAP x28
; LSL (Logical Shift Left) is a subroutine to left shift a number given an input
; Input: R0 = word to be shifted, R1 = number of times to shift
; Output: R0 = shifted word
;;;;
LSL ;-----------------------------------;x1016
                        ;
    ST  R1,LSL_SR1      ;
    ADD R1,R1,#0        ; Update CC for number of times
LSL_OL  
    BRnz    LSL_END     ; If times <= 0 branch to end
    ADD R0,R0,R0        ; Left shift R0
    ADD R1,R1,#-1       ; Decrement times
    BRnzp   LSL_OL      ;
LSL_END                 ;
    LD  R1,LSL_SR1      ;
    RET                 ;
LSL_SR1 .BLKW   1   ;
    ;-----------------------------------;x101E

;;;; TRAP x29
; LSR(Logical Shift Right) is a subroutine to do a right shift a number given an input
; Input: R0 = word to be shifted, R1 = number of times to shift
; Output: R0 = shifted word
; It works by clearing the first "times" bits then doing the CSR
;;;;
LSR ;-----------------------------------;x101F
    ADD R1,R1,#0        ;
    BRz LSR_RET         ; If R1 = 0, do nothing
    ST  R1,LSR_SR1      ;
    ST  R2,LSR_SR2      ;
    ST  R7,LSR_SR7      ;
    LD  R2,LSR_N16      ;
LSR_FIX 
    ADD R2,R1,R2        ; Add R1 and -16
    BRnz    LSR_CONT    ; If it's negative, that means it doesn't need more subtracting
    ADD R1,R2,#0        ; Move the subtracted result into R1
    BRnzp   LSR_FIX     ; Return to fix to subtract again
LSR_CONT                ; R1 should have a fixed number of times now
    ST  R1,LSR_SR1T     ; Temp storage of number of times
    LEA R2,LSR_LU       ;
    ADD R1,R1,R2        ; Get the address of the particular mask into R1
    LDR R2,R1,0         ; Load the mask into R2
    LD  R1,LSR_SR1T     ; Get the fixed times into R1
    AND R0,R0,R2        ; Mask the input with R2
    JSR CSR             ; circular right shift the masked input
LSR_END
    LD  R1,LSR_SR1      ;
    LD  R2,LSR_SR2      ;
    LD  R7,LSR_SR7      ;
LSR_RET 
    RET                 ;
LSR_16  .FILL   16      ; 16
LSR_N16 .FILL   -16     ; -16
                    ; Mask lookup table
LSR_LU  
    .FILL   xFFFF       ; 1111 1111 1111 1111
    .FILL   xFFFE       ; 1111 1111 1111 1110
    .FILL   xFFFC       ; 1111 1111 1111 1100
    .FILL   xFFF8       ; 1111 1111 1111 1000
    .FILL   xFFF0       ; 1111 1111 1111 0000
    .FILL   xFFE0       ; 1111 1111 1110 0000
    .FILL   xFFC0       ; 1111 1111 1100 0000
    .FILL   xFF80       ; 1111 1111 1000 0000
    .FILL   xFF00       ; 1111 1111 0000 0000
    .FILL   xFE00       ; 1111 1110 0000 0000
    .FILL   xFC00       ; 1111 1100 0000 0000
    .FILL   xF800       ; 1111 1000 0000 0000
    .FILL   xF000       ; 1111 0000 0000 0000
    .FILL   xE000       ; 1110 0000 0000 0000
    .FILL   xC000       ; 1100 0000 0000 0000
    .FILL   x8000       ; 1000 0000 0000 0000
    .FILL   x0000       ; 0000 0000 0000 0000
LSR_SR1 .BLKW   1       ;
LSR_SR2 .BLKW   1       ;
LSR_SR7 .BLKW   1       ;
LSR_SR1T    .BLKW   1       ;
    ;-----------------------------------;x104A
    
;;;; TRAP x2A
; CSL (Circular Shift Left) is a subroutine to circular left shift a number given an input
; Input: R0 = word to be shifted, R1 = number of times to shift
; Output: R0 = shifted word
; Note: It's basically LSL with two more lines of code. Didn't want to have too many inputs for LSL
;;;;
CSL ;-----------------------------------;x104B
    ST  R1,CSL_SR1      ;
    ST  R2,CSL_SR2      ;
    ST  R7,CSL_SR7      ;
    ADD R1,R1,#0        ; Update CC for number of times
CSL_OL  
    BRnz    CSL_END     ; If times <=0, branch to end
    ADD R2,R0,#0        ; R2 = R0
    ST  R1,CSL_Temp1    ; Store times in temp storage
    AND R1,R1,#0        ;
    ADD R1,R1,#1        ; Set R1 to 1 (do one left shift)
    JSR LSL             ; Do a logical left shift
    ADD R2,R2,#0        ; Get CC for word pre-shift
    BRzp    CSL_CONT    ; If the word pre-shift was negative, add 1 to replace the lost MSB
    ADD R0,R0,#1        ;
CSL_CONT
    LD  R1,CSL_Temp1    ; Retrieve times from temp storage
    ADD R1,R1,#-1       ; Decrement times
    BRnzp   CSL_OL      ;
CSL_END
    LD  R1,CSL_SR1      ;
    LD  R2,CSL_SR2      ;
    LD  R7,CSL_SR7      ;
    RET
CSL_SR1     .BLKW   1   ;
CSL_SR2     .BLKW   1   ;
CSL_SR7     .BLKW   1   ;
CSL_Temp1   .BLKW   1   ; Temp storage for times
    ;-----------------------------------;x1062

;;;; TRAP x2B
; CSR (Circular Shift Right) is a subroutine to do a "quick" circular right shift a number given an input, by doing circular left shifts
; Input: R0 = word to be shifted, R1 = number of times to shift
; Output: R0 = shifted word
; # of CSL = 16 - R1
;;;;    
CSR ;-----------------------------------;x1063
    ADD R1,R1,#0        ; Get CC for times
    BRz CSR_END         ; If it's zero, no right shifting
    ST  R1,CSR_SR1      ;
    ST  R2,CSR_SR2      ;
    ST  R7,CSR_SR7      ;
    LD  R2,CSR_N16      ;
CSR_FIX ADD R2,R1,R2    ; Add R1 and -16
    BRz CSR_END         ; If it results in zero, that means the shift ultimately does nothing
    BRn CSR_CONT        ; If it's negative, that means it doesn't need more subtracting
    ADD R1,R2,#0        ; Move the subtracted result into R1
    BRnzp   CSR_FIX     ; Return to fix to subtract again
CSR_CONT                ; R1 should have a fixed number of times now
    NOT R1,R1           ; Negate R1
    ADD R1,R1,#1
    LD  R2,CSR_16       ; R2 = 16
    ADD R1,R1,R2        ; R1 = 16 - times
    JSR CSL             ; Do a circular left shift 16-R1 times
CSR_END
    LD  R1,CSR_SR1      ;
    LD  R2,CSR_SR2      ;
    LD  R7,CSR_SR7      ;
    RET
CSR_16  .FILL   16      ;
CSR_N16 .FILL   -16     ;
CSR_SR1 .BLKW   1       ;
CSR_SR2 .BLKW   1       ;
CSR_SR7 .BLKW   1       ;
    ;-----------------------------------;x107B
    
;;;; TRAP x2C
; ASR (Arithmetic Shift Right) is a subroutine to arithmetic right shift a number given an input
; Input: R0 = word to be shifted, R1 = number of times to shift
; Output: R0 = shifted word
; Note:
;;;;
ASR ;-----------------------------------;x107C
    ST  R1,ASR_SR1      ;
    ST  R7,ASR_SR7      ;
    ADD R1,R1,#0        ; Update CC for number of times
ASR_OL  
    BRnz    ASR_END     ; If times <=0, branch to end
    ST  R1,ASR_Temp1    ; Store times in temp storage
    AND R1,R1,#0        ;
    ADD R1,R1,#1        ; Set R1 to 1 (do one left shift)
    JSR LSR             ; Do a logical right shift
    LD  R1,ASR_MSB      ;
    ADD R0,R0,R1        ; Fill the void with a 1
ASR_CONT    
    LD  R1,ASR_Temp1    ; Retrieve times from temp storage
    ADD R1,R1,#-1       ; Decrement times
    BRnzp   ASR_OL      ;
ASR_END
    LD  R1,ASR_SR1      ;
    LD  R7,ASR_SR7      ;
    RET
ASR_MSB     .FILL   x8000   ;
ASR_SR1     .BLKW   1       ;
ASR_SR7     .BLKW   1       ;
ASR_Temp1   .BLKW   1       ; Temp storage for times
    ;-----------------------------------;x108F

;-----------------------------;
;------------Math ------------;
;-----------------------------;

;;;; TRAP x2D
; Subroutine Multiply
; Input: R0 = A, R1 = B
; Output: R0 = A * B
; This multiply subroutine works like a long multiplication problem
; Uses LC3-Extended TRAPs
;;;;

; R0 = A    Number A
; R1 = 0    
; R2 = B    Number B
; R3 = 01   Mask
; R4 = 0000 Output
; R5 = temp
; A * B 
MUL ;-----------------------------------;x1090
    ST  R0,MUL_SR0  ;
    ST  R1,MUL_SR1  ;
    ST  R2,MUL_SR2  ;
    ST  R3,MUL_SR3  ;
    ST  R4,MUL_SR4  ;
    ST  R5,MUL_SR5  ;
    ST  R7,MUL_SR7  ;
    ; Set up values
    ADD R2,R1,#0    ; R2 = B
    AND R1,R1,#0    ; R1 = 0
    LD  R3,MUL_MASK ; R3 = 01
    AND R4,R4,#0    ; R4 = 0000
MUL_REPEAT
    AND R5,R2,R3    ; Check the current mask against B to see if A should be added
    BRz MUL_SKIP    ; If there is a 0, skip
    ;TRAP    x28     ; Left shift A by R1 times to get a summation thing
    JSR LSL         ;
    ADD R4,R0,R4    ; Add the shifted A to the output
    LD  R0,MUL_SR0  ; The original A into R0
MUL_SKIP
    ADD R1,R1,#1    ; Increment number of shift times
    ADD R3,R3,R3    ; Left shift the mask
    LD  R5,MUL_N15  ; Load the comparison 15
    ADD R5,R1,R5    ; Compare R1 times to 15
    BRn MUL_REPEAT  ; If R1 is less than 15 (R1 - 15 < 0) result is good; else repeat
    ADD R0,R4,#0    ; Move R4 output into R0
    LD  R1,MUL_SR1  ;
    LD  R2,MUL_SR2  ;
    LD  R3,MUL_SR3  ;
    LD  R4,MUL_SR4  ;
    LD  R5,MUL_SR5  ;
    LD  R7,MUL_SR7  ;
    RET
MUL_N15 .FILL   -15 ;
MUL_MASK .FILL   1  ;
MUL_SR0 .BLKW   1   ;
MUL_SR1 .BLKW   1   ;
MUL_SR2 .BLKW   1   ;
MUL_SR3 .BLKW   1   ;
MUL_SR4 .BLKW   1   ;
MUL_SR5 .BLKW   1   ;
MUL_SR7 .BLKW   1   ;
    ;-----------------------------------;x10B5
;;;; TRAP x2E
; Subroutine Divide
; Input: R0 = C: Dividend, R1 = D:Divisor
; Output: R0 = C / D : Quotient, R1 = Remainder
; This divide routine is a slow divider. Aww. I can't into long division
;;;;
DIV ;-----------------------------------;x10B6
    ST  R2,DIV_SR2      ;
    ST  R3,DIV_SR3      ;
                        ;Count number of negative numbers
                        ;It works by NOT, since negative/positive is a binary thing
    AND R3,R3,#0        ; Clear R3
    ADD R0,R0,#0        ; Get CC of R0
    BRzp    DIV_1       ; If it's negative, NOT R3
    NOT R3,R3           ;
    NOT R0,R0           ; Negate R0 so division works
    ADD R0,R0,#1        ;
DIV_1
    ADD R1,R1,#0        ; Get CC of R1
    BRp DIV_2           ; If it's negative, NOT R3
    BRz DIV_END         ; R1 CAN NOT BE 0
    NOT R3,R3           ;
    NOT R1,R1           ; Negate R0 so division works
    ADD R1,R1,#1        ;
DIV_2
    ST  R3,DIV_NEG      ;
    ADD R2,R0,#0        ; R2 = C
    ADD R3,R1,#0        ; R3 = D
    NOT R3,R3           ; R3 = (-D)
    ADD R3,R3,#1        ;
    AND R0,R0,#0        ; Clear R0 for output
DIV_LOOP    
    ADD R2,R2,#0        ; update CC for R2
    BRz DIV_LOOPZ       ;
    BRn DIV_LOOPN       ; If it extends too far, subtract 1 from quotient
    ADD R2,R2,R3        ; R2 += (-D)
    ADD R0,R0,#1        ;
    BRnzp   DIV_LOOP    ;
DIV_LOOPN
    ADD R0,R0,#-1       ;
    ADD R1,R2,#0        ; Move leftover into R1
    NOT R3,R3           ; Negate R3 (Divisor) so now it's D
    ADD R3,R3,#1        ; 
    ADD R1,R1,R3        ; Form the remainder
    BRnzp   DIV_LOOPE   ;
DIV_LOOPZ
    AND R1,R1,#0        ; clear remainder
DIV_LOOPE
    LD  R3,DIV_NEG      ; Get whether or not it was negative
    BRzp    DIV_END     ; CC = R3
    NOT R0,R0           ; Negate R0
    ADD R0,R0,#1        ;
    NOT R1,R1           ; Negate R1
    ADD R1,R1,#1        ;
DIV_END
    LD  R2,DIV_SR2      ;
    LD  R3,DIV_SR3      ;
    RET
DIV_NEG .BLKW   1       ;
DIV_SR2 .BLKW   1       ;
DIV_SR3 .BLKW   1       ;

;;;;; TRAP x2F
; Subroutine Power
; Input:  R0 = X, R1 = Y
; Output: R0 = X exp(Y)
; Note: Calls MUL, uses LC3-Extended TRAPs
;;;;;
POW ;-----------------------------------;x10E3
    ST  R1,POW_SR1      ;
    ST  R2,POW_SR2      ;
    ST  R7,POW_SR7      ;
    ADD R2,R1,#0        ; R2 = Y
    ADD R1,R0,#0        ; R1 = X
    ADD R2,R2,#-1       ; Update CC for R2, decrement once because X^1 = X
    BRz POW_ZERO        ;
POW_LOOP    
    BRnz    POW_END     ; Once Y is 0, end
    JSR MUL             ;
    ADD R2,R2,#-1       ; Decrement Y
    BRnzp   POW_LOOP    ; Loop back again
POW_ZERO
    AND R0,R0,#0        ; Set R0 to 1 if Y is 0
    ADD R0,R0,#1        ;
POW_END 
    LD  R1,POW_SR1      ;
    LD  R2,POW_SR2      ;
    LD  R7,POW_SR7      ;
    RET
POW_SR1 .BLKW   1       ;
POW_SR2 .BLKW   1       ;
POW_SR7 .BLKW   1       ;
    ;-----------------------------------;x10F6
    .END
