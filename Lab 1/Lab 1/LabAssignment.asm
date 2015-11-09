; -------------------------------------------------------------------------------------	;
;	Лабораторная работа №1 по курсу Программирование на языке ассемблера				;
;	Вариант №1.2.																		;
;	Выполнил студент Смирнов Михаил, 344 группа.										;
;																						;
;	Исходный модуль LabAssignment.asm													;
;	Содержит функции на языке ассемблера, разработанные в соответствии с заданием		;
; -------------------------------------------------------------------------------------	;
;	Задание: Реализовать прямое и обратное преобразования Фурье
;	Формат данных сигнала: __int8
;	Формат данных спектра: float
;	Размер (количество отсчетов) сигнала и спектра: 8
;	Способ реализации: DFT 2x2 + 2 бабочки 
;	Отсчеты спектра являются комплексными числами. Причем действительные части хранятся
;	в первой половине массива, а мнимые - во второй
.DATA
root qword 3FE6A09E667F3BCDh    ; Константа sqrt(2) / 2.
signalLength qword 4020000000000000h
two	dword 2.0

.CODE
; -------------------------------------------------------------------------------------	;
; void CalculateSpectrum(spectrum_type* Spectrum, signal_type* Signal)					;
;	Прямое преобразование Фурье. Вычисляет спектр Spectrum по сигналу Signal			;
;	Типы данных spectrum_type и signal_type, а так же разимер сигнала					;
;	определяются в файле Tuning.h														;
; -------------------------------------------------------------------------------------	;
CalculateSpectrum PROC	; [RCX] - Spectrum, [RDX] - Signal
; Ниже представлены явные формулы для вычисления элементов спектра.
; Для чётных элементов спектра.
; X[0] = (x[0] + x[4]) + (x[2] + x[6]) + (x[1] + x[5]) + (x[3] + x[7])
; X[2] = (x[0] + x[4]) - (x[2] + x[6])
; X[4] = (x[0] + x[4]) + (x[2] + x[6]) - (x[1] + x[5]) - (x[3] + x[7])
; X[6] = (x[0] + x[4]) - (x[2] + x[6])
; X[8] = 0
; X[10] =							   - (x[1] + x[5]) + (x[3] + x[7])
; X[12] = 0
; X[14] =							   + (x[1] + x[5]) - (x[3] + x[7])
; Для нечётных элементов спектра.
; X[1]  =   x[0] - x[4] + root * ((x[1] - x[5]) - (x[3] - x[7]))
; X[9]  = -(x[2] - x[6]) - root * ((x[1] - x[5]) + (x[3] - x[7]))
; X[3]  =   x[0] - x[4] - root * ((x[1] - x[5]) - (x[3] - x[7]))
; X[11] =   x[2] - x[6] - root * ((x[1] - x[5]) + (x[3] - x[7]))
; X[5]  =   x[0] - x[4] - root * ((x[1] - x[5]) - (x[3] - x[7]))
; X[13] = -(x[2] - x[6]) + root * ((x[1] - x[5]) + (x[3] - x[7]))
; X[7]  =   x[0] - x[4] + root * ((x[1] - x[5]) - (x[3] - x[7]))
; X[15] =   x[2] - x[6] + root * ((x[1] - x[5]) + (x[3] - x[7]))

fninit							; Инициализируем FPU без ожидания.

; Вычисление чётных элементов спектра.
xor RAX, RAX
movsx RAX, byte ptr[RDX] + 3	; Кладём x[3] в RAX.
mov [RCX] + 28, RAX				; X[7] вычисляется перед выходом из процедуры, поэтому будем использовать для хранения промежуточных данных.
fild word ptr[RCX] + 28			; Загрузили на стек х[3].
xor RAX, RAX
movsx RAX, byte ptr[RDX] + 7	; Кладём x[7] в RAX.
mov [RCX] + 28, RAX
fild word ptr[RCX] + 28			; Загрузили на стек х[7].
faddp							; Стек: (x[3] + x[7]).

xor RAX, RAX
movsx RAX, byte ptr[RDX] + 1	; Кладём x[1] в RAX.
mov [RCX] + 28, RAX
fild word ptr[RCX] + 28			; Загрузили на стек х[1].
xor RAX, RAX
movsx RAX, byte ptr[RDX] + 5	; Кладём x[5] в RAX.
mov [RCX] + 28, RAX
fild word ptr[RCX] + 28			; Загрузили на стек х[5].
faddp							; Стек: (x[1] + x[5]), (x[3] + x[7]).

xor RAX, RAX
movsx RAX, byte ptr[RDX] + 2	; Кладём x[2] в RAX.
mov [RCX] + 28, RAX
fild word ptr[RCX] + 28			; Загрузили на стек х[2].
xor RAX, RAX
movsx RAX, byte ptr[RDX] + 6	; Кладём x[6] в RAX.
mov [RCX] + 28, RAX
fild word ptr[RCX] + 28			; Загрузили на стек х[6].
faddp							; Стек: (x[2] + x[6]), (x[1] + x[5]), (x[3] + x[7]).

xor RAX, RAX					; Обнуляем RAX.
movsx RAX, byte ptr[RDX]		; Кладём x[0] в RAX.
mov [RCX] + 28, RAX			
fild word ptr[RCX] + 28			; Загрузили на стек x[0].
xor RAX, RAX
movsx RAX, byte ptr[RDX] + 4	; Кладём x[4] в RAX.
mov [RCX] + 28, RAX
fild word ptr[RCX] + 28 		; Загрузили на стек х[4].
faddp							; Стек: (x[0] + x[4]), (x[2] + x[6]), (x[1] + x[5]), (x[3] + x[7]).

; Стек: (x[0] + x[4]), (x[2] + x[6]), (x[1] + x[5]), (x[3] + x[7]).
; Далее для удобства обозначим элементы x04, x26, x15, x37 соответственно.
fld st							; Стек: x04, x04, x26, x15, x37.
fsub st, st(2)					; Стек: x04 - x26, x04, x26, x15, x37.
fst real4 ptr[RCX] + 8			; Записали X[2].
fstp real4 ptr[RCX] + 24		; Записали X[6]. 
								; Стек: x04, x26, x15, x37.
faddp							; Стек: x04 + x26, x15, x37.
fadd st, st(1)					; Стек: x04 + x26 + x15, x15, x37.
fadd st, st(2)					; Стек: x04 + x26 + x15 + x37, x15, x37.
fst real4 ptr[RCX]				; Записали X[0].
fsub st, st(1) 					; Стек: x04 + x26 + x37, x15, x37.
fsub st, st(1)					; Стек: x04 + x26 - x15 + x37, x15, x37.
fsub st, st(2)					; Стек: x04 + x26 - x15, x15, x37.
fsub st, st(2)					; Стек: x04 + x26 - x15 - x37, x15, x37.
fstp real4 ptr[RCX] + 16		; Записали X[4]. 
								; Стек: x15, x37.
fsub st, st(1)					; Стек: x15 - x37.
fst real4 ptr[RCX] + 56			; Записали X[14].
fchs							; Стек: x37 - x15.
fstp real4 ptr[RCX] + 40		; Записали X[10].
								; X[8] и X[12] равны 0.

; Вычисление нечётных элементов спектра.
xor RAX, RAX
movsx RAX, byte ptr[RDX] + 3	; Кладём x[3] в RAX.
mov [RCX] + 28, RAX
fild word ptr[RCX] + 28			; Загрузили на стек х[3].
xor RAX, RAX
movsx RAX, byte ptr[RDX] + 7	; Кладём x[7] в RAX.
mov [RCX] + 28, RAX
fild word ptr[RCX] + 28			; Загрузили на стек х[7].
fsubp							; Стек: (x[3] - x[7]).

xor RAX, RAX
movsx RAX, byte ptr[RDX] + 1	; Кладём x[1] в RAX.
mov [RCX] + 28, RAX
fild word ptr[RCX] + 28			; Загрузили на стек х[1].
xor RAX, RAX
movsx RAX, byte ptr[RDX] + 5	; Кладём x[5] в RAX.
mov [RCX] + 28, RAX
fild word ptr[RCX] + 28			; Загрузили на стек х[5].
fsubp							; Стек: (x[1] - x[5]), (x[3] - x[7]).

xor RAX, RAX
movsx RAX, byte ptr[RDX] + 2	; Кладём x[2] в RAX.
mov [RCX] + 28, RAX
fild word ptr[RCX] + 28			; Загрузили на стек х[2].
xor RAX,RAX
movsx RAX, byte ptr[RDX] + 6	; Кладём x[6] в RAX.
mov [RCX] + 28, RAX
fild word ptr[RCX] + 28			; Загрузили на стек х[6].
fsubp							; Стек: (x[2] - x[6]), (x[1] - x[5]), (x[3] - x[7]).

xor RAX, RAX
movsx RAX, byte ptr[RDX] 		; Кладём x[0] в RAX.
mov [RCX] + 28, RAX
fild word ptr[RCX] + 28			; Загрузили на стек х[0].
xor RAX, RAX
movsx RAX, byte ptr[RDX] + 4	; Кладём x[4] в RAX.
mov [RCX] + 28, RAX
fild word ptr[RCX] + 28			; Загрузили на стек х[4].
fsubp							; Стек: (x[0] - x[4]), (x[2] - x[6]), (x[1] - x[5]), (x[3] - x[7]).

; Стек: (x[0] - x[4]), (x[2] - x[6]), (x[1] - x[5]), (x[3] - x[7]).
; Далее для удобства обозначим элементы x04, x26, x15, x37 соответственно.
fld st(2)						; Стек: x15, x04, x26, x15, x37.
fsub st, st(4)					; Стек: x15 - x37, x04, x26, x15, x37.
fmul root						; Стек: root * (x15 - x37), x04, x26, x15, x37.
fxch st(1)						; Стек: x04, root * (x15 - x37), x26, x15, x37.
fadd st, st(1)					; Стек: x04 + root * (x15 - x37), root * (x15 - x37), x26, x15, x37.
fst real4 ptr[RCX] + 4			; Записали X[1].
fst real4 ptr[RCX] + 28			; Записали X[7].
fsub st, st(1)					; Стек: x04, root * (x15 - x37), x26, x15, x37.
fsub st(0), st(1)				; Стек: x04 - root * (x15 - x37), root * (x15 - x37), x26, x15, x37.
fst real4 ptr[RCX] + 12			; Записали X[3].
fstp real4 ptr[RCX] + 20		; Записали X[5].
								; Стек: root * (x15 - x37), x26, x15, x37.
fld  st(3)						; Стек: x37, root * (x15 - x37), x26, x15, x37.
fmul root						; Стек: root * x37, root * (x15 - x37), x26, x15, x37.
fmul two						; Стек: 2 * root * x37, root * (x15 - x37), x26, x15, x37.
faddp 							; Стек: root * (x15 + x37), x26, x15, x37.
fxch st(1) 						; Стек: x26, root * (x15 + x37), x15, x37.
fadd st, st(1) 					; Стек: x26 + root * (x15 + x37), root * (x15 + x37), x15, x37.
fst real4 ptr[RCX] + 60			; Записали X[15].
fchs							; Стек: -x26 - root * (x15 + x37), root * (x15 + x37), x15, x37.
fst real4 ptr[RCX] + 36			; Записали X[9].
fadd st, st(1)					; Стек: -x26, root * (x15 + x37), x15, x37.
fadd st, st(1)					; Стек: -x26 + root * (x15 + x37), root * (x15 + x37), x15, x37.
fst real4 ptr[RCX] + 52			; Записали X[13].
fchs							; Стек: x26 - root * (x15 + x37), root * (x15 + x37), x15, x37.
fstp real4 ptr[RCX] + 44		; Записали X[11].

; Очищаем стек.
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
;	Обратное преобразование Фурье. Вычисляет сигнал Signal по спектру Spectrum			;
;	Типы данных spectrum_type и signal_type, а так же размер сигнала					;
;	определяются в файле Tuning.h														;
; -------------------------------------------------------------------------------------	;
RecoverSignal PROC	; [RCX] - Signal
					; [RDX] - Spectrum
; Ниже представлены явные формулы для вычисления элементов сигнала.
; Для чётных элементов сигнала.
; x[0] = (X[0] + X[4]) + (X[2] + X[6]) + (X[1] + X[5]) + (X[3] + X[7])
; x[2] = (X[0] + X[4]) - (X[2] + X[6]) - (X[9] + X[13]) + (X[11] + X[15])
; x[4] = (X[0] + X[4]) + (X[2] + X[6]) - (X[1] + X[5]) - (X[3] + X[7])
; x[6] = (X[0] + X[4]) - (X[2] + X[6]) + (X[9] + X[13]) - (X[11] + X[15])

; Для нечётных элементов сигнала.
; x[1] = (X[0] - X[4]) - (X[10] - X[14]) + root * ((X[1] - X[5]) - (X[3] - X[7]) - (X[9] - X[13]) - (X[11] - X[15]))    
; x[3] = (X[0] - X[4]) + (X[10] - X[14]) - root * ((X[1] - X[5]) - (X[3] - X[7]) + (X[9] - X[13]) + (X[11] - X[15]))
; x[5] = (X[0] - X[4]) - (X[10] - X[14]) - root * ((X[1] - X[5]) - (X[3] - X[7]) - (X[9] - X[13]) - (X[11] - X[15]))    
; x[7] = (X[0] - X[4]) + (X[10] - X[14]) + root * ((X[1] - X[5]) - (X[3] - X[7]) + (X[9] - X[13]) + (X[11] - X[15]))

; Промежуточные 16-битные переменные будем класть по адресу [RDX] + 32, так как X[8] в вычислениях не используется.

; Вычисление чётных элементов сигнала.
fninit

fld real4 ptr[RDX] + 4			; Загрузили X[1].
fld real4 ptr[RDX] + 20			; Загрузили X[5].
faddp							; Стек: (X[1] + X[5]).
fld real4 ptr[RDX] + 12			; Загрузили X[3].
								; Стек: X[3], (X[1] + X[5]).
faddp							; Стек: X[3] + (X[1] + X[5]).
fld real4 ptr[RDX] + 28			; Загрузили X[7].
								; Стек: X[7], X[3] + (X[1] + X[5]).
faddp							; Стек: (X[3] + X[7]) + (X[1] + X[5]).

fld real4 ptr[RDX] + 8			; Загрузили X[2].
								; Стек: X[2], (X[3] + X[7]) + (X[1] + X[5]).
fld real4 ptr[RDX] + 24			; Загрузили X[6].
								; Стек: X[6], X[2], (X[3] + X[7]) + (X[1] + X[5]).
faddp							; Стек: X[2] + X[6], (X[3] + X[7]) + (X[1] + X[5]).
fld real4 ptr[RDX]				; Загрузили X[0].
fld real4 ptr[RDX] + 16		; Загрузили X[4].
faddp							; Стек: (X[0] + X[4]), (X[2] + X[6]), (X[3] + X[7]) + (X[1] + X[5]).

; Стек: (x[0] + x[4]), (x[2] + x[6]), (x[1] + x[5]) + (x[3] + x[7]).
; Далее для удобства обозначим элементы x04, x26, x15, x37 соответственно.
fadd st, st(1)					; Стек: x04 + x26, x26, x15 + x37.
fadd st, st(2)					; Стек: x04 + x26 + x15 + x37, x26, x15 + x37.

fdiv signalLength				; Перед записью в ответ необходимо поделить на длину сигнала.
xor ax, ax
fist word ptr[RDX] + 32
mov ax, word ptr[RDX] + 32
mov byte ptr[RCX], al			; Записали x[0]. 
fmul signalLength				

fsub st, st(2)					; Стек: x04 + x26, x26, x37 + x15
fsub st, st(2)					; Стек: x04 + x26 - x37 - x15, x26, x37 + x15

fdiv signalLength
xor ax, ax
fist word ptr[RDX] + 32
mov ax, word ptr[RDX] + 32
mov byte ptr[RCX] + 4, al		; Записали x[4].
fmul signalLength				

fadd st, st(2)					; Стек: x04 + x26, x26, x37 + x15
fsub st, st(1)					; Стек: x04, x26, x37 + x15
fsub st, st(1)					; Стек: x04 - x26, x26, x37 + x15

fld real4 ptr[RDX] + 36			; Загрузили X[9].
fld real4 ptr[RDX] + 52			; Загрузили X[13].
faddp							; Стек: (X[9] + X[13]) ...
fld real4 ptr[RDX] + 44			; Загрузили X[11].
								; Стек: X[11], (X[9] + X[13]) ...
fsubp							; Стек: - X[11] + (X[9] + X[13]) ...
fld real4 ptr[RDX] + 60			; Загрузили X[15].
								; Стек: X[15], - X[11] + (X[9] + X[13]) ...
fsubp							; Стек: (X[9] + X[13]) - (X[11] + X[15]) ...

fadd st, st(1)					; Стек: x04 - x26 + x9_13 - x11_15, x04 - x26, x26, x37 + x15
fdiv signalLength
xor ax, ax
fist word ptr[RDX] + 32
mov ax, word ptr[RDX] + 32
mov byte ptr[RCX] + 6, al		; Записали x[6]. 
fmul signalLength

fsub st, st(1)					; Стек: x9_13 - x11_15, x04 - x26, x26, x37 + x15
fchs							; Стек: - x9_13 + x11_15, x04 - x26, x26, x37 + x15
faddp							; Стек: x04 - x26 - x9_13 + x11_15, x26, x37 + x15

fdiv signalLength
xor ax,ax
fistp word ptr[RDX] + 32		; Стек: x26, x37 + x15
mov ax, word ptr[RDX] + 32
mov byte ptr[RCX] + 2, al		; Записали x[2].
fsubp st(0), st(0)
fsubp st(0), st(0)

; Вычисление нечётных элементов сигнала.
fld real4 ptr[RDX]				; Загрузили X[0].
fld real4 ptr[RDX] + 16			; Загрузили X[4].
fsubp							; X[0] - X[4].
fld real4 ptr[RDX] + 40			; Загрузили X[10].
fld real4 ptr[RDX] + 56			; Загрузили X[14].
fsubp							; X[10] - X[14], X[0] - X[4].

fld real4 ptr[RDX] + 4			; Загрузили X[1].
fld real4 ptr[RDX] + 20			; Загрузили X[5]
fsubp							; X[1] - X[5].
fld real4 ptr[RDX] + 12			; Загрузили X[3]
fsubp							; X[1] - X[5] - X[3].
fld real4 ptr[RDX] + 28			; Загрузили X[7].
faddp							; (X[1] - X[5]) - (X[3] - X[7]).

fld real4 ptr[RDX] + 36			; Загрузили X[9].
fld real4 ptr[RDX] + 52			; Загрузили X[13].
fsubp							; X[9] - X[13].
fld real4 ptr[RDX] + 44			; Загрузили X[11].
faddp							; X[9] - X[13] + X[11].
fld real4 ptr[RDX] + 60			; Загрузили X[15].
fsubp							; (X[9] - X[13]) + (X[11] - X[15]).


; x[1] = (X[0] - X[4]) - (X[10] - X[14]) + root * ((X[1] - X[5]) - (X[3] - X[7]) - (X[9] - X[13]) - (X[11] - X[15]))    
; x[3] = (X[0] - X[4]) + (X[10] - X[14]) - root * ((X[1] - X[5]) - (X[3] - X[7]) + (X[9] - X[13]) + (X[11] - X[15]))
; x[5] = (X[0] - X[4]) - (X[10] - X[14]) - root * ((X[1] - X[5]) - (X[3] - X[7]) - (X[9] - X[13]) - (X[11] - X[15]))    
; x[7] = (X[0] - X[4]) + (X[10] - X[14]) + root * ((X[1] - X[5]) - (X[3] - X[7]) + (X[9] - X[13]) + (X[11] - X[15]))

								; Стек: x9_13 + x11_15, x15 - x37, x10_14, x04.
fadd st, st(1)					; Стек: x15 - x37 + x9_13 + x11_15, x15 - x37, x10_14, x04.
fmul root						; Стек: root * (x15 - x37 + x9_13 + x11_15), x15 - x37, x10_14, x04.
fadd st, st(2)					; Стек: x10_14 + root * (x15 - x37 + x9_13 + x11_15), x15 - x37, x10_14, x04.
fadd st, st(3)					; Стек: x04 + x10_14 + root * (x15 - x37 + x9_13 + x11_15), x15 - x37, x10_14, x04.

fdiv signalLength
xor ax, ax
fist word ptr[RDX] + 32
mov ax, word ptr[RDX] + 32
mov byte ptr[RCX] + 7, al		; Записали x[7].
fmul signalLength

fchs							; Стек: - x04 - x10_14 - root * (x15 - x37 + x9_13 + x11_15), x15 - x37, x10_14, x04.
fadd st, st(2)					; Стек: - x04 - root * (x15 - x37 + x9_13 + x11_15), x15 - x37, x10_14, x04.
fadd st, st(3)					; Стек: - root * (x15 - x37 + x9_13 + x11_15), x15 - x37, x10_14, x04.
fadd st, st(2)					; Стек: x10_14 - root * (x15 - x37 + x9_13 + x11_15), x15 - x37, x10_14, x04.
fadd st, st(3)					; Стек: x04 + x10_14 - root * (x15 - x37 + x9_13 + x11_15), x15 - x37, x10_14, x04.

fdiv signalLength
xor ax, ax
fist word ptr[RDX] + 32
mov ax, word ptr[RDX] + 32
mov byte ptr[RCX] + 3, al		; Записали x[3].
fmul signalLength

fld st(1)						; Стек: x15 - x37, x04 + x10_14 - root * (x15 - x37 + x9_13 + x11_15), x15 - x37, x10_14, x04.
fmul root						; Стек: root * (x15 - x37), x04 + x10_14 - root * (x15 - x37 + x9_13 + x11_15), x15 - x37, x10_14, x04.
fmul two						; Стек: 2 * root * (x15 - x37), x04 + x10_14 - root * (x15 - x37 + x9_13 + x11_15), x15 - x37, x10_14, x04.
faddp							; Стек: x04 + x10_14 - root * (- x15 + x37 + x9_13 + x11_15), x15 - x37, x10_14, x04. Что эквивалентно:
								; Стек: x04 + x10_14 + root * (x15 - x37 - x9_13 - x11_15), x15 - x37, x10_14, x04.

fsub st, st(2)					; Стек: x04 + root * (x15 - x37 - x9_13 - x11_15), x15 - x37, x10_14, x04.
fsub st, st(2)					; Стек: x04 - x10_14 + root * (x15 - x37 - x9_13 - x11_15), x15 - x37, x10_14, x04.

fdiv signalLength
xor ax, ax
fist word ptr[RDX] + 32
mov ax, word ptr[RDX] + 32
mov byte ptr[RCX] + 1, al		; Записали x[1].
fmul signalLength

fchs							; Стек: - x04 + x10_14 - root * (x15 - x37 - x9_13 - x11_15), x15 - x37, x10_14, x04.
fsub st, st(2)					; Стек: - x04 - root * (x15 - x37 - x9_13 - x11_15), x15 - x37, x10_14, x04.
fadd st, st(3)					; Стек: - root * (x15 - x37 - x9_13 - x11_15), x15 - x37, x10_14, x04.
fsub st, st(2)					; Стек: - x10_14 - root * (x15 - x37 - x9_13 - x11_15), x15 - x37, x10_14, x04.
fadd st, st(3)					; Стек: x04 - x10_14 - root * (x15 - x37 - x9_13 - x11_15), x15 - x37, x10_14, x04.

fdiv signalLength
xor ax, ax
fistp word ptr[RDX] + 32
mov ax, word ptr[RDX] + 32
mov byte ptr[RCX] + 5, al		; Записали x[5].
fmul signalLength

; Очищаем стек.
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
