; -------------------------------------------------------------------------------------	;
;	������������ ������ �1 �� ����� ���������������� �� ����� ����������				;
;	������� �1.2.																		;
;	�������� ������� ������� ������, 344 ������.										;
;																						;
;	�������� ������ LabAssignment.asm													;
;	�������� ������� �� ����� ����������, ������������� � ������������ � ��������		;
; -------------------------------------------------------------------------------------	;
;	�������: ����������� ������ � �������� �������������� �����
;	������ ������ �������: __int8
;	������ ������ �������: float
;	������ (���������� ��������) ������� � �������: 8
;	������ ����������: DFT 2x2 + 2 ������� 
;	������� ������� �������� ������������ �������. ������ �������������� ����� ��������
;	� ������ �������� �������, � ������ - �� ������
.DATA
root qword 3FE6A09E667F3BCDh    ; ��������� sqrt(2) / 2.
signalLength qword 4020000000000000h
two	dword 2.0

.CODE
; -------------------------------------------------------------------------------------	;
; void CalculateSpectrum(spectrum_type* Spectrum, signal_type* Signal)					;
;	������ �������������� �����. ��������� ������ Spectrum �� ������� Signal			;
;	���� ������ spectrum_type � signal_type, � ��� �� ������� �������					;
;	������������ � ����� Tuning.h														;
; -------------------------------------------------------------------------------------	;
CalculateSpectrum PROC	; [RCX] - Spectrum, [RDX] - Signal
; ���� ������������ ����� ������� ��� ���������� ��������� �������.
; ��� ������ ��������� �������.
; X[0] = (x[0] + x[4]) + (x[2] + x[6]) + (x[1] + x[5]) + (x[3] + x[7])
; X[2] = (x[0] + x[4]) - (x[2] + x[6])
; X[4] = (x[0] + x[4]) + (x[2] + x[6]) - (x[1] + x[5]) - (x[3] + x[7])
; X[6] = (x[0] + x[4]) - (x[2] + x[6])
; X[8] = 0
; X[10] =							   - (x[1] + x[5]) + (x[3] + x[7])
; X[12] = 0
; X[14] =							   + (x[1] + x[5]) - (x[3] + x[7])
; ��� �������� ��������� �������.
; X[1]  =   x[0] - x[4] + root * ((x[1] - x[5]) - (x[3] - x[7]))
; X[9]  = -(x[2] - x[6]) - root * ((x[1] - x[5]) + (x[3] - x[7]))
; X[3]  =   x[0] - x[4] - root * ((x[1] - x[5]) - (x[3] - x[7]))
; X[11] =   x[2] - x[6] - root * ((x[1] - x[5]) + (x[3] - x[7]))
; X[5]  =   x[0] - x[4] - root * ((x[1] - x[5]) - (x[3] - x[7]))
; X[13] = -(x[2] - x[6]) + root * ((x[1] - x[5]) + (x[3] - x[7]))
; X[7]  =   x[0] - x[4] + root * ((x[1] - x[5]) - (x[3] - x[7]))
; X[15] =   x[2] - x[6] + root * ((x[1] - x[5]) + (x[3] - x[7]))

fninit							; �������������� FPU ��� ��������.

push RBP						; ���������� RBP				
mov RBP, RSP					; ����������� ��������� ����� � RBP				
sub RSP, 8						; ��������� ������ ��� ��������� ����������

; ���������� ������ ��������� �������.
movsx RAX, byte ptr[RDX] + 3	; ����� x[3] � RAX.
mov [RBP - 2], RAX
fild word ptr[RBP - 2]			; ��������� �� ���� �[3].
movsx RAX, byte ptr[RDX] + 7	; ����� x[7] � RAX.
mov [RBP - 2], RAX
fild word ptr[RBP - 2]			; ��������� �� ���� �[7].
faddp							; ����: (x[3] + x[7]).

movsx RAX, byte ptr[RDX] + 1	; ����� x[1] � RAX.
mov [RBP - 2], RAX
fild word ptr[RBP - 2]			; ��������� �� ���� �[1].
movsx RAX, byte ptr[RDX] + 5	; ����� x[5] � RAX.
mov [RBP - 2], RAX
fild word ptr[RBP - 2]			; ��������� �� ���� �[5].
faddp							; ����: (x[1] + x[5]), (x[3] + x[7]).

movsx RAX, byte ptr[RDX] + 2	; ����� x[2] � RAX.
mov [RBP - 2], RAX
fild word ptr[RBP - 2]			; ��������� �� ���� �[2].
movsx RAX, byte ptr[RDX] + 6	; ����� x[6] � RAX.
mov [RBP - 2], RAX
fild word ptr[RBP - 2]			; ��������� �� ���� �[6].
faddp							; ����: (x[2] + x[6]), (x[1] + x[5]), (x[3] + x[7]).

movsx RAX, byte ptr[RDX]		; ����� x[0] � RAX.
mov [RBP - 2], RAX
fild word ptr[RBP - 2]			; ��������� �� ���� x[0].
movsx RAX, byte ptr[RDX] + 4	; ����� x[4] � RAX.
mov [RBP - 2], RAX
fild word ptr[RBP - 2]	 		; ��������� �� ���� �[4].
faddp							; ����: (x[0] + x[4]), (x[2] + x[6]), (x[1] + x[5]), (x[3] + x[7]).

; ����: (x[0] + x[4]), (x[2] + x[6]), (x[1] + x[5]), (x[3] + x[7]).
; ����� ��� �������� ��������� �������� x04, x26, x15, x37 ��������������.
fld st							; ����: x04, x04, x26, x15, x37.
fsub st, st(2)					; ����: x04 - x26, x04, x26, x15, x37.
fst real4 ptr[RCX] + 8			; �������� X[2].
fstp real4 ptr[RCX] + 24		; �������� X[6]. 
                                ; ����: x04, x26, x15, x37.
faddp							; ����: x04 + x26, x15, x37.
fadd st, st(1)					; ����: x04 + x26 + x15, x15, x37.
fadd st, st(2)					; ����: x04 + x26 + x15 + x37, x15, x37.
fst real4 ptr[RCX]				; �������� X[0].
fsub st, st(1) 					; ����: x04 + x26 + x37, x15, x37.
fsub st, st(1)					; ����: x04 + x26 - x15 + x37, x15, x37.
fsub st, st(2)					; ����: x04 + x26 - x15, x15, x37.
fsub st, st(2)					; ����: x04 + x26 - x15 - x37, x15, x37.
fstp real4 ptr[RCX] + 16		; �������� X[4]. 
                                ; ����: x15, x37.
fsub st, st(1)					; ����: x15 - x37.
fst real4 ptr[RCX] + 56			; �������� X[14].
fchs							; ����: x37 - x15.
fstp real4 ptr[RCX] + 40		; �������� X[10].
                                ; X[8] � X[12] ����� 0.

; ���������� �������� ��������� �������.
movsx RAX, byte ptr[RDX] + 3	; ����� x[3] � RAX.
mov [RBP - 2], RAX
fild word ptr[RBP - 2]			; ��������� �� ���� �[3].
movsx RAX, byte ptr[RDX] + 7	; ����� x[7] � RAX.
mov [RBP - 2], RAX
fild word ptr[RBP - 2]			; ��������� �� ���� �[7].
fsubp							; ����: (x[3] - x[7]).

movsx RAX, byte ptr[RDX] + 1	; ����� x[1] � RAX.
mov [RBP - 2], RAX
fild word ptr[RBP - 2]			; ��������� �� ���� �[1].
movsx RAX, byte ptr[RDX] + 5	; ����� x[5] � RAX.
mov [RBP - 2], RAX
fild word ptr[RBP - 2]			; ��������� �� ���� �[5].
fsubp							; ����: (x[1] - x[5]), (x[3] - x[7]).

movsx RAX, byte ptr[RDX] + 2	; ����� x[2] � RAX.
mov [RBP - 2], RAX
fild word ptr[RBP - 2]			; ��������� �� ���� �[2].
movsx RAX, byte ptr[RDX] + 6	; ����� x[6] � RAX.
mov [RBP - 2], RAX
fild word ptr[RBP - 2]			; ��������� �� ���� �[6].
fsubp							; ����: (x[2] - x[6]), (x[1] - x[5]), (x[3] - x[7]).

movsx RAX, byte ptr[RDX] 		; ����� x[0] � RAX.
mov [RBP - 2], RAX
fild word ptr[RBP - 2]			; ��������� �� ���� �[0].
movsx RAX, byte ptr[RDX] + 4	; ����� x[4] � RAX.
mov [RBP - 2], RAX
fild word ptr[RBP - 2]			; ��������� �� ���� �[4].
fsubp							; ����: (x[0] - x[4]), (x[2] - x[6]), (x[1] - x[5]), (x[3] - x[7]).

; ����: (x[0] - x[4]), (x[2] - x[6]), (x[1] - x[5]), (x[3] - x[7]).
; ����� ��� �������� ��������� �������� x04, x26, x15, x37 ��������������.
fld st(2)						; ����: x15, x04, x26, x15, x37.
fsub st, st(4)					; ����: x15 - x37, x04, x26, x15, x37.
fmul root						; ����: root * (x15 - x37), x04, x26, x15, x37.
fxch st(1)						; ����: x04, root * (x15 - x37), x26, x15, x37.
fadd st, st(1)					; ����: x04 + root * (x15 - x37), root * (x15 - x37), x26, x15, x37.
fst real4 ptr[RCX] + 4			; �������� X[1].
fst real4 ptr[RCX] + 28			; �������� X[7].
fsub st, st(1)					; ����: x04, root * (x15 - x37), x26, x15, x37.
fsub st(0), st(1)				; ����: x04 - root * (x15 - x37), root * (x15 - x37), x26, x15, x37.
fst real4 ptr[RCX] + 12			; �������� X[3].
fstp real4 ptr[RCX] + 20		; �������� X[5].
                                ; ����: root * (x15 - x37), x26, x15, x37.
fld  st(3)						; ����: x37, root * (x15 - x37), x26, x15, x37.
fmul root						; ����: root * x37, root * (x15 - x37), x26, x15, x37.
fmul two						; ����: 2 * root * x37, root * (x15 - x37), x26, x15, x37.
faddp 							; ����: root * (x15 + x37), x26, x15, x37.
fxch st(1) 						; ����: x26, root * (x15 + x37), x15, x37.
fadd st, st(1) 					; ����: x26 + root * (x15 + x37), root * (x15 + x37), x15, x37.
fst real4 ptr[RCX] + 60			; �������� X[15].
fchs							; ����: -x26 - root * (x15 + x37), root * (x15 + x37), x15, x37.
fst real4 ptr[RCX] + 36			; �������� X[9].
fadd st, st(1)					; ����: -x26, root * (x15 + x37), x15, x37.
fadd st, st(1)					; ����: -x26 + root * (x15 + x37), root * (x15 + x37), x15, x37.
fst real4 ptr[RCX] + 52			; �������� X[13].
fchs							; ����: x26 - root * (x15 + x37), root * (x15 + x37), x15, x37.
fstp real4 ptr[RCX] + 44		; �������� X[11].

leave							; �������������� ��������� ����� � �������������� RBP.

; ������� ����.
ffree st(0)
ffree st(1)
ffree st(2)
ffree st(3)
ffree st(4)
ffree st(5)
ffree st(6)
ffree st(7)
    ret
CalculateSpectrum ENDP

; -------------------------------------------------------------------------------------	;
; void RecoverSignal(signal_type* Signal, spectrum_type* Spectrum)						;
;	�������� �������������� �����. ��������� ������ Signal �� ������� Spectrum			;
;	���� ������ spectrum_type � signal_type, � ��� �� ������ �������					;
;	������������ � ����� Tuning.h														;
; -------------------------------------------------------------------------------------	;
RecoverSignal PROC	; [RCX] - Signal
                    ; [RDX] - Spectrum
; ���� ������������ ����� ������� ��� ���������� ��������� �������.
; ��� ������ ��������� �������.
; x[0] = (X[0] + X[4]) + (X[2] + X[6]) + (X[1] + X[5]) + (X[3] + X[7])
; x[2] = (X[0] + X[4]) - (X[2] + X[6]) - (X[9] + X[13]) + (X[11] + X[15])
; x[4] = (X[0] + X[4]) + (X[2] + X[6]) - (X[1] + X[5]) - (X[3] + X[7])
; x[6] = (X[0] + X[4]) - (X[2] + X[6]) + (X[9] + X[13]) - (X[11] + X[15])

; ��� �������� ��������� �������.
; x[1] = (X[0] - X[4]) - (X[10] - X[14]) + root * ((X[1] - X[5]) - (X[3] - X[7]) - (X[9] - X[13]) - (X[11] - X[15]))    
; x[3] = (X[0] - X[4]) + (X[10] - X[14]) - root * ((X[1] - X[5]) - (X[3] - X[7]) + (X[9] - X[13]) + (X[11] - X[15]))
; x[5] = (X[0] - X[4]) - (X[10] - X[14]) - root * ((X[1] - X[5]) - (X[3] - X[7]) - (X[9] - X[13]) - (X[11] - X[15]))    
; x[7] = (X[0] - X[4]) + (X[10] - X[14]) + root * ((X[1] - X[5]) - (X[3] - X[7]) + (X[9] - X[13]) + (X[11] - X[15]))

; ���������� ������ ��������� �������.
fninit

push RBP						; ���������� RBP				
mov RBP, RSP					; ����������� ��������� ����� � RBP				
sub RSP, 8						; ��������� ������ ��� ��������� ����������

fld real4 ptr[RDX] + 4			; ��������� X[1].
fld real4 ptr[RDX] + 20			; ��������� X[5].
faddp							; ����: (X[1] + X[5]).
fld real4 ptr[RDX] + 12			; ��������� X[3].
                                ; ����: X[3], (X[1] + X[5]).
faddp							; ����: X[3] + (X[1] + X[5]).
fld real4 ptr[RDX] + 28			; ��������� X[7].
                                ; ����: X[7], X[3] + (X[1] + X[5]).
faddp							; ����: (X[3] + X[7]) + (X[1] + X[5]).

fld real4 ptr[RDX] + 8			; ��������� X[2].
                                ; ����: X[2], (X[3] + X[7]) + (X[1] + X[5]).
fld real4 ptr[RDX] + 24			; ��������� X[6].
                                ; ����: X[6], X[2], (X[3] + X[7]) + (X[1] + X[5]).
faddp							; ����: X[2] + X[6], (X[3] + X[7]) + (X[1] + X[5]).
fld real4 ptr[RDX]				; ��������� X[0].
fld real4 ptr[RDX] + 16			; ��������� X[4].
faddp							; ����: (X[0] + X[4]), (X[2] + X[6]), (X[3] + X[7]) + (X[1] + X[5]).

; ����: (x[0] + x[4]), (x[2] + x[6]), (x[1] + x[5]) + (x[3] + x[7]).
; ����� ��� �������� ��������� �������� x04, x26, x15, x37 ��������������.
fadd st, st(1)					; ����: x04 + x26, x26, x15 + x37.
fadd st, st(2)					; ����: x04 + x26 + x15 + x37, x26, x15 + x37.

fdiv signalLength				; ����� ������� � ����� ���������� �������� �� ����� �������.
fist word ptr[RBP - 2]
mov AX, word ptr[RBP - 2]
mov byte ptr[RCX], AL			; �������� x[0]. 
fmul signalLength				

fsub st, st(2)					; ����: x04 + x26, x26, x37 + x15
fsub st, st(2)					; ����: x04 + x26 - x37 - x15, x26, x37 + x15

fdiv signalLength
fist word ptr[RBP - 2]
mov AX, word ptr[RBP - 2]
mov byte ptr[RCX] + 4, AL		; �������� x[4].
fmul signalLength				

fadd st, st(2)					; ����: x04 + x26, x26, x37 + x15
fsub st, st(1)					; ����: x04, x26, x37 + x15
fsub st, st(1)					; ����: x04 - x26, x26, x37 + x15

fld real4 ptr[RDX] + 36			; ��������� X[9].
fld real4 ptr[RDX] + 52			; ��������� X[13].
faddp							; ����: (X[9] + X[13]) ...
fld real4 ptr[RDX] + 44			; ��������� X[11].
                                ; ����: X[11], (X[9] + X[13]) ...
fsubp							; ����: - X[11] + (X[9] + X[13]) ...
fld real4 ptr[RDX] + 60			; ��������� X[15].
                                ; ����: X[15], - X[11] + (X[9] + X[13]) ...
fsubp							; ����: (X[9] + X[13]) - (X[11] + X[15]) ...

fadd st, st(1)					; ����: x04 - x26 + x9_13 - x11_15, x04 - x26, x26, x37 + x15
fdiv signalLength
fist word ptr[RBP - 2]
mov AX, word ptr[RBP - 2]
mov byte ptr[RCX] + 6, AL		; �������� x[6]. 
fmul signalLength

fsub st, st(1)					; ����: x9_13 - x11_15, x04 - x26, x26, x37 + x15
fchs							; ����: - x9_13 + x11_15, x04 - x26, x26, x37 + x15
faddp							; ����: x04 - x26 - x9_13 + x11_15, x26, x37 + x15

fdiv signalLength
fistp word ptr[RBP - 2]			; ����: x26, x37 + x15
mov AX, word ptr[RBP - 2]
mov byte ptr[RCX] + 2, AL		; �������� x[2].
fsubp st(0), st(0)
fsubp st(0), st(0)

; ���������� �������� ��������� �������.
fld real4 ptr[RDX]				; ��������� X[0].
fld real4 ptr[RDX] + 16			; ��������� X[4].
fsubp							; X[0] - X[4].
fld real4 ptr[RDX] + 40			; ��������� X[10].
fld real4 ptr[RDX] + 56			; ��������� X[14].
fsubp							; X[10] - X[14], X[0] - X[4].

fld real4 ptr[RDX] + 4			; ��������� X[1].
fld real4 ptr[RDX] + 20			; ��������� X[5]
fsubp							; X[1] - X[5].
fld real4 ptr[RDX] + 12			; ��������� X[3]
fsubp							; X[1] - X[5] - X[3].
fld real4 ptr[RDX] + 28			; ��������� X[7].
faddp							; (X[1] - X[5]) - (X[3] - X[7]).

fld real4 ptr[RDX] + 36			; ��������� X[9].
fld real4 ptr[RDX] + 52			; ��������� X[13].
fsubp							; X[9] - X[13].
fld real4 ptr[RDX] + 44			; ��������� X[11].
faddp							; X[9] - X[13] + X[11].
fld real4 ptr[RDX] + 60			; ��������� X[15].
fsubp							; (X[9] - X[13]) + (X[11] - X[15]).

                                ; ����: x9_13 + x11_15, x15 - x37, x10_14, x04.
fadd st, st(1)					; ����: x15 - x37 + x9_13 + x11_15, x15 - x37, x10_14, x04.
fmul root						; ����: root * (x15 - x37 + x9_13 + x11_15), x15 - x37, x10_14, x04.
fadd st, st(2)					; ����: x10_14 + root * (x15 - x37 + x9_13 + x11_15), x15 - x37, x10_14, x04.
fadd st, st(3)					; ����: x04 + x10_14 + root * (x15 - x37 + x9_13 + x11_15), x15 - x37, x10_14, x04.

fdiv signalLength
fist word ptr[RBP - 2]
mov AX, word ptr[RBP - 2]
mov byte ptr[RCX] + 7, AL		; �������� x[7].
fmul signalLength

fchs							; ����: - x04 - x10_14 - root * (x15 - x37 + x9_13 + x11_15), x15 - x37, x10_14, x04.
fadd st, st(2)					; ����: - x04 - root * (x15 - x37 + x9_13 + x11_15), x15 - x37, x10_14, x04.
fadd st, st(3)					; ����: - root * (x15 - x37 + x9_13 + x11_15), x15 - x37, x10_14, x04.
fadd st, st(2)					; ����: x10_14 - root * (x15 - x37 + x9_13 + x11_15), x15 - x37, x10_14, x04.
fadd st, st(3)					; ����: x04 + x10_14 - root * (x15 - x37 + x9_13 + x11_15), x15 - x37, x10_14, x04.

fdiv signalLength
fist word ptr[RBP - 2]
mov AX, word ptr[RBP - 2]
mov byte ptr[RCX] + 3, AL		; �������� x[3].
fmul signalLength

fld st(1)						; ����: x15 - x37, x04 + x10_14 - root * (x15 - x37 + x9_13 + x11_15), x15 - x37, x10_14, x04.
fmul root					    ; ����: root * (x15 - x37), x04 + x10_14 - root * (x15 - x37 + x9_13 + x11_15), x15 - x37, x10_14, x04.
fmul two						; ����: 2 * root * (x15 - x37), x04 + x10_14 - root * (x15 - x37 + x9_13 + x11_15), x15 - x37, x10_14, x04.
faddp							; ����: x04 + x10_14 - root * (- x15 + x37 + x9_13 + x11_15), x15 - x37, x10_14, x04. ��� ������������:
                                ; ����: x04 + x10_14 + root * (x15 - x37 - x9_13 - x11_15), x15 - x37, x10_14, x04.

fsub st, st(2)					; ����: x04 + root * (x15 - x37 - x9_13 - x11_15), x15 - x37, x10_14, x04.
fsub st, st(2)					; ����: x04 - x10_14 + root * (x15 - x37 - x9_13 - x11_15), x15 - x37, x10_14, x04.

fdiv signalLength
fist word ptr[RBP - 2]
mov AX, word ptr[RBP - 2]
mov byte ptr[RCX] + 1, AL		; �������� x[1].
fmul signalLength

fchs							; ����: - x04 + x10_14 - root * (x15 - x37 - x9_13 - x11_15), x15 - x37, x10_14, x04.
fsub st, st(2)					; ����: - x04 - root * (x15 - x37 - x9_13 - x11_15), x15 - x37, x10_14, x04.
fadd st, st(3)					; ����: - root * (x15 - x37 - x9_13 - x11_15), x15 - x37, x10_14, x04.
fsub st, st(2)					; ����: - x10_14 - root * (x15 - x37 - x9_13 - x11_15), x15 - x37, x10_14, x04.
fadd st, st(3)					; ����: x04 - x10_14 - root * (x15 - x37 - x9_13 - x11_15), x15 - x37, x10_14, x04.

fdiv signalLength
fistp word ptr[RBP - 2]
mov AX, word ptr[RBP - 2]
mov byte ptr[RCX] + 5, AL		; �������� x[5].
fmul signalLength

leave							; �������������� ��������� ����� � �������������� RBP.

; ������� ����.
ffree st(0)                
ffree st(1)
ffree st(2)
ffree st(3)
ffree st(4)
ffree st(5)
ffree st(6)
ffree st(7)
    ret
RecoverSignal ENDP
END
