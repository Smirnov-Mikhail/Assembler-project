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

; ���������� ������ ��������� �������.
xor RAX, RAX
movsx RAX, byte ptr[RDX] + 3	; ����� x[3] � RAX.
mov [RCX] + 28, RAX				; X[7] ����������� ����� ������� �� ���������, ������� ����� ������������ ��� �������� ������������� ������.
fild word ptr[RCX] + 28			; ��������� �� ���� �[3].
xor RAX, RAX
movsx RAX, byte ptr[RDX] + 7	; ����� x[7] � RAX.
mov [RCX] + 28, RAX
fild word ptr[RCX] + 28			; ��������� �� ���� �[7].
faddp							; ����: (x[3] + x[7]).

xor RAX, RAX
movsx RAX, byte ptr[RDX] + 1	; ����� x[1] � RAX.
mov [RCX] + 28, RAX
fild word ptr[RCX] + 28			; ��������� �� ���� �[1].
xor RAX, RAX
movsx RAX, byte ptr[RDX] + 5	; ����� x[5] � RAX.
mov [RCX] + 28, RAX
fild word ptr[RCX] + 28			; ��������� �� ���� �[5].
faddp							; ����: (x[1] + x[5]), (x[3] + x[7]).

xor RAX, RAX
movsx RAX, byte ptr[RDX] + 2	; ����� x[2] � RAX.
mov [RCX] + 28, RAX
fild word ptr[RCX] + 28			; ��������� �� ���� �[2].
xor RAX, RAX
movsx RAX, byte ptr[RDX] + 6	; ����� x[6] � RAX.
mov [RCX] + 28, RAX
fild word ptr[RCX] + 28			; ��������� �� ���� �[6].
faddp							; ����: (x[2] + x[6]), (x[1] + x[5]), (x[3] + x[7]).

xor RAX, RAX					; �������� RAX.
movsx RAX, byte ptr[RDX]		; ����� x[0] � RAX.
mov [RCX] + 28, RAX			
fild word ptr[RCX] + 28			; ��������� �� ���� x[0].
xor RAX, RAX
movsx RAX, byte ptr[RDX] + 4	; ����� x[4] � RAX.
mov [RCX] + 28, RAX
fild word ptr[RCX] + 28 		; ��������� �� ���� �[4].
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
xor RAX, RAX
movsx RAX, byte ptr[RDX] + 3	; ����� x[3] � RAX.
mov [RCX] + 28, RAX
fild word ptr[RCX] + 28			; ��������� �� ���� �[3].
xor RAX, RAX
movsx RAX, byte ptr[RDX] + 7	; ����� x[7] � RAX.
mov [RCX] + 28, RAX
fild word ptr[RCX] + 28			; ��������� �� ���� �[7].
fsubp							; ����: (x[3] - x[7]).

xor RAX, RAX
movsx RAX, byte ptr[RDX] + 1	; ����� x[1] � RAX.
mov [RCX] + 28, RAX
fild word ptr[RCX] + 28			; ��������� �� ���� �[1].
xor RAX, RAX
movsx RAX, byte ptr[RDX] + 5	; ����� x[5] � RAX.
mov [RCX] + 28, RAX
fild word ptr[RCX] + 28			; ��������� �� ���� �[5].
fsubp							; ����: (x[1] - x[5]), (x[3] - x[7]).

xor RAX, RAX
movsx RAX, byte ptr[RDX] + 2	; ����� x[2] � RAX.
mov [RCX] + 28, RAX
fild word ptr[RCX] + 28			; ��������� �� ���� �[2].
xor RAX,RAX
movsx RAX, byte ptr[RDX] + 6	; ����� x[6] � RAX.
mov [RCX] + 28, RAX
fild word ptr[RCX] + 28			; ��������� �� ���� �[6].
fsubp							; ����: (x[2] - x[6]), (x[1] - x[5]), (x[3] - x[7]).

xor RAX, RAX
movsx RAX, byte ptr[RDX] 		; ����� x[0] � RAX.
mov [RCX] + 28, RAX
fild word ptr[RCX] + 28			; ��������� �� ���� �[0].
xor RAX, RAX
movsx RAX, byte ptr[RDX] + 4	; ����� x[4] � RAX.
mov [RCX] + 28, RAX
fild word ptr[RCX] + 28			; ��������� �� ���� �[4].
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

; ������������� 16-������ ���������� ����� ������ �� ������ [RDX] + 32, ��� ��� X[8] � ����������� �� ������������.

; ���������� ������ ��������� �������.
fninit

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
fld real4 ptr[RDX] + 16		; ��������� X[4].
faddp							; ����: (X[0] + X[4]), (X[2] + X[6]), (X[3] + X[7]) + (X[1] + X[5]).

; ����: (x[0] + x[4]), (x[2] + x[6]), (x[1] + x[5]) + (x[3] + x[7]).
; ����� ��� �������� ��������� �������� x04, x26, x15, x37 ��������������.
fadd st, st(1)					; ����: x04 + x26, x26, x15 + x37.
fadd st, st(2)					; ����: x04 + x26 + x15 + x37, x26, x15 + x37.

fdiv signalLength				; ����� ������� � ����� ���������� �������� �� ����� �������.
xor ax, ax
fist word ptr[RDX] + 32
mov ax, word ptr[RDX] + 32
mov byte ptr[RCX], al			; �������� x[0]. 
fmul signalLength				

fsub st, st(2)					; ����: x04 + x26, x26, x37 + x15
fsub st, st(2)					; ����: x04 + x26 - x37 - x15, x26, x37 + x15

fdiv signalLength
xor ax, ax
fist word ptr[RDX] + 32
mov ax, word ptr[RDX] + 32
mov byte ptr[RCX] + 4, al		; �������� x[4].
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
xor ax, ax
fist word ptr[RDX] + 32
mov ax, word ptr[RDX] + 32
mov byte ptr[RCX] + 6, al		; �������� x[6]. 
fmul signalLength

fsub st, st(1)					; ����: x9_13 - x11_15, x04 - x26, x26, x37 + x15
fchs							; ����: - x9_13 + x11_15, x04 - x26, x26, x37 + x15
faddp							; ����: x04 - x26 - x9_13 + x11_15, x26, x37 + x15

fdiv signalLength
xor ax,ax
fistp word ptr[RDX] + 32		; ����: x26, x37 + x15
mov ax, word ptr[RDX] + 32
mov byte ptr[RCX] + 2, al		; �������� x[2].
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


; x[1] = (X[0] - X[4]) - (X[10] - X[14]) + root * ((X[1] - X[5]) - (X[3] - X[7]) - (X[9] - X[13]) - (X[11] - X[15]))    
; x[3] = (X[0] - X[4]) + (X[10] - X[14]) - root * ((X[1] - X[5]) - (X[3] - X[7]) + (X[9] - X[13]) + (X[11] - X[15]))
; x[5] = (X[0] - X[4]) - (X[10] - X[14]) - root * ((X[1] - X[5]) - (X[3] - X[7]) - (X[9] - X[13]) - (X[11] - X[15]))    
; x[7] = (X[0] - X[4]) + (X[10] - X[14]) + root * ((X[1] - X[5]) - (X[3] - X[7]) + (X[9] - X[13]) + (X[11] - X[15]))

								; ����: x9_13 + x11_15, x15 - x37, x10_14, x04.
fadd st, st(1)					; ����: x15 - x37 + x9_13 + x11_15, x15 - x37, x10_14, x04.
fmul root						; ����: root * (x15 - x37 + x9_13 + x11_15), x15 - x37, x10_14, x04.
fadd st, st(2)					; ����: x10_14 + root * (x15 - x37 + x9_13 + x11_15), x15 - x37, x10_14, x04.
fadd st, st(3)					; ����: x04 + x10_14 + root * (x15 - x37 + x9_13 + x11_15), x15 - x37, x10_14, x04.

fdiv signalLength
xor ax, ax
fist word ptr[RDX] + 32
mov ax, word ptr[RDX] + 32
mov byte ptr[RCX] + 7, al		; �������� x[7].
fmul signalLength

fchs							; ����: - x04 - x10_14 - root * (x15 - x37 + x9_13 + x11_15), x15 - x37, x10_14, x04.
fadd st, st(2)					; ����: - x04 - root * (x15 - x37 + x9_13 + x11_15), x15 - x37, x10_14, x04.
fadd st, st(3)					; ����: - root * (x15 - x37 + x9_13 + x11_15), x15 - x37, x10_14, x04.
fadd st, st(2)					; ����: x10_14 - root * (x15 - x37 + x9_13 + x11_15), x15 - x37, x10_14, x04.
fadd st, st(3)					; ����: x04 + x10_14 - root * (x15 - x37 + x9_13 + x11_15), x15 - x37, x10_14, x04.

fdiv signalLength
xor ax, ax
fist word ptr[RDX] + 32
mov ax, word ptr[RDX] + 32
mov byte ptr[RCX] + 3, al		; �������� x[3].
fmul signalLength

fld st(1)						; ����: x15 - x37, x04 + x10_14 - root * (x15 - x37 + x9_13 + x11_15), x15 - x37, x10_14, x04.
fmul root						; ����: root * (x15 - x37), x04 + x10_14 - root * (x15 - x37 + x9_13 + x11_15), x15 - x37, x10_14, x04.
fmul two						; ����: 2 * root * (x15 - x37), x04 + x10_14 - root * (x15 - x37 + x9_13 + x11_15), x15 - x37, x10_14, x04.
faddp							; ����: x04 + x10_14 - root * (- x15 + x37 + x9_13 + x11_15), x15 - x37, x10_14, x04. ��� ������������:
								; ����: x04 + x10_14 + root * (x15 - x37 - x9_13 - x11_15), x15 - x37, x10_14, x04.

fsub st, st(2)					; ����: x04 + root * (x15 - x37 - x9_13 - x11_15), x15 - x37, x10_14, x04.
fsub st, st(2)					; ����: x04 - x10_14 + root * (x15 - x37 - x9_13 - x11_15), x15 - x37, x10_14, x04.

fdiv signalLength
xor ax, ax
fist word ptr[RDX] + 32
mov ax, word ptr[RDX] + 32
mov byte ptr[RCX] + 1, al		; �������� x[1].
fmul signalLength

fchs							; ����: - x04 + x10_14 - root * (x15 - x37 - x9_13 - x11_15), x15 - x37, x10_14, x04.
fsub st, st(2)					; ����: - x04 - root * (x15 - x37 - x9_13 - x11_15), x15 - x37, x10_14, x04.
fadd st, st(3)					; ����: - root * (x15 - x37 - x9_13 - x11_15), x15 - x37, x10_14, x04.
fsub st, st(2)					; ����: - x10_14 - root * (x15 - x37 - x9_13 - x11_15), x15 - x37, x10_14, x04.
fadd st, st(3)					; ����: x04 - x10_14 - root * (x15 - x37 - x9_13 - x11_15), x15 - x37, x10_14, x04.

fdiv signalLength
xor ax, ax
fistp word ptr[RDX] + 32
mov ax, word ptr[RDX] + 32
mov byte ptr[RCX] + 5, al		; �������� x[5].
fmul signalLength

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
