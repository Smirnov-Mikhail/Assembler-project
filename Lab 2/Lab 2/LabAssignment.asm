; -------------------------------------------------------------------------------------	;
;	Лабораторная работа №2 по курсу Программирование на языке ассемблера				;
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
W4Re	real4 1.0, 0.0, -1.0, 0.0
W4Im	real4 0.0, -1.0, 0.0, 1.0
W81Re	real4 1.0, 0.70710678118654746, 0.0, -0.70710678118654746
W82Re	real4 -1.0, -0.70710678118654746, 0.0, 0.70710678118654746
W81Im	real4 0.0, -0.70710678118654746, -1.0, -0.70710678118654746
W82Im	real4 0.0, 0.70710678118654746, 1.0, 0.70710678118654746
half	real4 0.5, 0.5, 0.5, 0.5

.CODE
; -------------------------------------------------------------------------------------	;
; void CalculateSpectrum(spectrum_type* Spectrum, signal_type* Signal)					;
;	Прямое преобразование Фурье. Вычисляет спектр Spectrum по сигналу Signal			;
;	Типы данных spectrum_type и signal_type, а так же разимер сигнала					;
;	определяются в файле Tuning.h														;
; -------------------------------------------------------------------------------------	;
CalculateSpectrum PROC	; [RCX] - Spectrum
						; [RDX] - Signal
	sub rsp, 48
	VMOVDQU xmmword ptr[rsp], xmm6		; Сохраняем регистры.
	VMOVDQU xmmword ptr[rsp + 16], xmm7
	VMOVDQU xmmword ptr[rsp + 32], xmm8

	VPMOVSXBD xmm0, dword ptr[rdx]		; x0, x1, x2, x3.
	VPMOVSXBD xmm1, dword ptr[rdx + 4]	; x4, x5, x6, x7.

	CVTDQ2PS xmm0, xmm0					; Конвертируем в float.
	CVTDQ2PS xmm1, xmm1					; Конвертируем в float.

	VADDPS xmm2, xmm0, xmm1				; x0 + x4, x1 + x5, x2 + x6, x3 + x7.

	VSUBPS xmm3, xmm0, xmm1				; x0 - x4, x1 - x5, x2 - x6, x3 - x7.

	VSHUFPS xmm0, xmm2, xmm3, 00000000B		
	VSHUFPS xmm0, xmm0, xmm0, 11001100B	; x0 + x4, x0 - x4, x0 + x4, x0 - x4.
	
	VSHUFPS xmm1, xmm2, xmm3, 01010101B		
	VSHUFPS xmm1, xmm1, xmm1, 11001100B	; x1 + x5, x1 - x5, x1 + x5, x1 - x5.
								
	VSHUFPS xmm4, xmm2, xmm3, 10101010B		
	VSHUFPS xmm4, xmm4, xmm4, 11001100B	; x2 + x6, x2 - x6, x2 + x6, x2 - x6.
	
	VSHUFPS xmm5, xmm2, xmm3, 11111111B		
	VSHUFPS xmm5, xmm5, xmm5, 11001100B	; x3 + x7, x3 - x7, x3 + x7, x3 - x7.

	; DFT 4x4
	VMULPS xmm2, xmm4, w4Re 
	VADDPS xmm2, xmm0, xmm2
	VMULPS xmm4, xmm4, w4Im 
	VMULPS xmm3, xmm5, w4Re
	VADDPS xmm3, xmm1, xmm3	
	VMULPS xmm5, xmm5, w4Im

	; DFT 8x8 Re
	VMULPS xmm0, xmm3, w81Re
	VADDPS xmm0, xmm2, xmm0
	VFMADD231PS xmm2, xmm3, w82Re
	VFNMADD231PS xmm0, xmm5, w81Im
	VFNMADD231PS xmm2, xmm5, w82Im

	; DFT 8x8 Im
	VMULPS xmm7, xmm3, w81Im
	VADDPS xmm7, xmm4, xmm7
	VFMADD231PS xmm4, xmm3, w82Im
	VFMADD231PS xmm7, xmm5, w81Re
	VFMADD231PS xmm4, xmm5, w82Re

	VMOVDQU xmmword ptr[rcx], xmm0		; Записываем результаты.
	VMOVDQU xmmword ptr[rcx + 16], xmm2
	VMOVDQU xmmword ptr[rcx + 32], xmm7
	VMOVDQU xmmword ptr[rcx + 48], xmm4

	VMOVDQU xmm6, xmmword ptr[rsp]		; Восстанавливаем регистры.
	VMOVDQU xmm7, xmmword ptr[rsp + 16]
	VMOVDQU xmm8, xmmword ptr[rsp + 32]
	add rsp, 48

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
	sub rsp, 48
	VMOVDQU xmmword ptr[rsp], xmm6			; Сохраняем регистры.
	VMOVDQU xmmword ptr[rsp + 16], xmm7
	VMOVDQU xmmword ptr[rsp + 32], xmm8

	VMOVDQU xmm0, xmmword ptr[rdx]			; x0, x1, x2, x3.
	VMOVDQU xmm1, xmmword ptr[rdx + 4*4]	; x4, x5, x6, x7.
	VMOVDQU xmm2, xmmword ptr[rdx + 4*8]	; x8, x9, x10, x11.
	VMOVDQU xmm3, xmmword ptr[rdx + 4*12]	; x12, x13, x14, x15.
	
	VADDPS xmm4, xmm0, xmm1		
	VMULPS xmm4, xmm4, half		; (x0 + x4) / 2, (x1 + x5) / 2, (x2 + x6) / 2, (x3 + x7) / 2. Обозначим a0, a1, a2, a3.
	VADDPS xmm5, xmm2, xmm3
	VMULPS xmm5, xmm5, half		; (x8 + x12) / 2, (x9 + x13) / 2, (x10 + x14) / 2, (x11 + x15) / 2. Обозначим b0, b1, b2, b3.

	VMULPS xmm6, xmm0, w81Re
	VMULPS xmm7, xmm1, w82Re
	VADDPS xmm6, xmm6, xmm7
	VMULPS xmm7, xmm2, w81Im
	VADDPS xmm6, xmm6, xmm7
	VMULPS xmm7, xmm3, w82Im
	VADDPS xmm6, xmm6, xmm7	
	VMULPS xmm6, xmm6, half		; Вещественная часть нижней бабочки. Обозначим a4, a5, a6, a7.
 
	VMULPS xmm7, xmm0, w82Im
	VMULPS xmm8, xmm1, w81Im
	VADDPS xmm7, xmm7, xmm8
	VMULPS xmm8, xmm2, w81Re
	VADDPS xmm7, xmm7, xmm8
	VMULPS xmm8, xmm3, w82Re
	VADDPS xmm7, xmm7, xmm8	
	VMULPS xmm7, xmm7, half		; Мнимая часть нижней бабочки. Обозначим b4, b5, b6, b7.

	; Ниже представлены явные формулы для вычисления.
	; x0 = ((a0 + a2) / 2 + a3) / 2.
	; x1 = ((a4 + a6) / 2 + a7) / 2.
	; x2 = ((a0 - a2) / 2 + b3) / 2.
	; x3 = ((a4 - a6) / 2 + b7) / 2.
	
	; x4 = ((a0 + a2) / 2 - a3) / 2.
	; x5 = ((a4 + a6) / 2 - a7) / 2.
	; x6 = ((a0 - a2) / 2 - b3) / 2.
	; x7 = ((a4 - a6) / 2 - b7) / 2.

	VSHUFPS xmm0, xmm4, xmm6, 00000000B
	VSHUFPS xmm0, xmm0, xmm0, 00110011B	; a0, a4, a0, a4.
	VSHUFPS xmm1, xmm4, xmm6, 10101010B
	VSHUFPS xmm1, xmm1, xmm1, 11001100B	; a2, a6, a2, a6.

	VADDPS xmm2, xmm0, xmm1
	VSUBPS xmm3, xmm0, xmm1
	VMULPS xmm2, xmm2, half
	VMULPS xmm3, xmm3, half

	VSHUFPS xmm0, xmm2, xmm3, 00010001B	; (a0 + a2) / 2, (a4 + a6) / 2, (a0 - a2) / 2, (a4 - a6) / 2.
	VMOVAPS xmm1, xmm0

	VSHUFPS xmm2, xmm4, xmm5, 11111111B	; a3, a3, b3, b3.
	VSHUFPS xmm2, xmm2, xmm2, 11001100B	; a3, b3, a3, b3.
	VBLENDPS xmm2, xmm2, xmm6, 1000B	; a3, b3, a3, a7.
	VSHUFPS xmm2, xmm2, xmm2, 11110100B	; a3, b3, a7, a7.
	VBLENDPS xmm2, xmm2, xmm7, 1000B	; a3, b3, a7, b7.
	VSHUFPS xmm2, xmm2, xmm2, 11011000B	; a3, a7, b3, b7.
	
	VADDPS xmm0, xmm0, xmm2
	VSUBPS xmm1, xmm1, xmm2
	VMULPS xmm0, xmm0, half				; x0, x1, x2, x3.
	VMULPS xmm1, xmm1, half				; x4, x5, x6, x7.

	VCVTPS2DQ xmm0, xmm0				; Записываем результаты.
	VCVTPS2DQ xmm1, xmm1
	VPACKSSDW xmm0, xmm0, xmm1
	VPACKSSWB xmm0, xmm0, xmm0
	VMOVQ qword ptr[rcx], xmm0

	VMOVDQU xmm6, xmmword ptr[rsp]		; Восстанавливаем регистры.
	VMOVDQU xmm7, xmmword ptr[rsp + 16]
	VMOVDQU xmm8, xmmword ptr[rsp + 32]
	add rsp, 48

	ret
RecoverSignal ENDP
END
