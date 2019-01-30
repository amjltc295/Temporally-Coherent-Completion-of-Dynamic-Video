;Optimized double class functions for MATLAB on x86 computers.
;Copyright © Marcel Leutenegger, 2003-2008, École Polytechnique Fédérale de Lausanne (EPFL),
;Laboratoire d'Optique Biomédicale (LOB), BM - Station 17, 1015 Lausanne, Switzerland.
;
;    This library is free software; you can redistribute it and/or modify it under
;    the terms of the GNU Lesser General Public License as published by the Free
;    Software Foundation; version 2.1 of the License.
;
;    This library is distributed in the hope that it will be useful, but WITHOUT ANY
;    WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
;    PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.
;
;    You should have received a copy of the GNU Lesser General Public License along
;    with this library; if not, write to the Free Software Foundation, Inc.,
;    51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

[segment .data align=16]
fln2:	db	0xAC,0x79,0xCF,0xD1,0xF7,0x17,0x72,0xB1,0xFD,0x3F	; ln(2)/2
align	4
f1o2:	dd	0x3F000000						; 1/2
fpi2:	db	0x18,0x2D,0x44,0x54,0xFB,0x21,0xF9,0x3F			; pi/2


[segment .text align=16]
global	_fasinh


;bool fasinh(double* or, double* oi, const double* sr, const double* si, int n)
;
_fasinh:
	push ebx
	push edi
	push esi
	fninit
	xor eax,eax
	mov ecx,[esp+32]	; n
	mov esi,[esp+28]	; si
	sub ecx,byte 1
	mov edi,[esp+24]	; sr
	test esi,esi
	mov edx,[esp+20]	; oi
	mov ebx,[esp+16]	; or
       jz near	.16
.1:	fld qword [edi+ecx*8]
	fxam
	fnstsw ax
	sahf
       jc near	.5
       jz near	.9
	fabs			; |a|
	fld qword [esi+ecx*8]
	fxam
	fnstsw ax
	sahf
       jc near	.7
       jz near	.14
	fld st1
	fmul st0,st0		; a^2
	fld st2
	fmul st0,st2		; |a|*b
	fld st2
	fmul st0,st0		; b^2
	fsubp st2,st0
	fld1
	faddp st2,st0		; Re(x) = 1 + a^2 - b^2
	fld st1
	fabs
	fxch st2
	fucomi st2
	fmul st0,st0
	fld st1
	fadd st0,st0		; Im(x) = 2*|a|*b
	fmul st0,st0
	faddp st1,st0
	fsqrt			; |x|
	faddp st2,st0
	fxch
	fmul dword [f1o2]
	fsqrt
	fdiv st1,st0
       jz	.3
	test ax,0x200
       jz	.2
	fchs
.2:	fxch
	fabs
.3:	faddp st3,st0		; Re(y) = |a| + Re(sqrt(x))
	cmp byte [edi+ecx*8+7],0
	faddp st1,st0		; Im(y) = b + Im(sqrt(x))
	fld tword [fln2]
	fld st2
	fmul st0,st0
	fld st2
	fmul st0,st0
	faddp st1,st0		; |y|^2
	fyl2x
       jns	.4
	fchs
.4:	fstp qword [ebx+ecx*8]
	fxch
	fpatan
	fstp qword [edx+ecx*8]
	sub ecx,byte 1
       jns	.1
	mov eax,1
	pop esi
	pop edi
	pop ebx
       retn
.5:    jnp	.6		; nan
	fld qword [esi+ecx*8]
	fucomi st0
       jp	.6		; nan
	fld st1
	fabs
	fpatan
	mov eax,0x10000
       jmp	.11
.6:	fst st1
       jmp	.11
.7:    jnp	.6
	cmp byte [edi+ecx*8+7],0
	fld st0
	fabs
       jns	.8
	fchs
.8:	fxch st2
	fabs
	fpatan
	mov eax,0x10000
       jmp	.11
.9:	fld qword [esi+ecx*8]	; imaginary part
	fxam
	fnstsw ax
	sahf
       jc	.13
       jz	.11
	fld st0
	fmul st0,st0
	fld1
	fucomi st1
	fsubp st1,st0		; b^2 - 1
	fabs
       jz	.10		; |b| = 1
	fsqrt
       jnc	.12		; |b| < 1
	fldln2
	fxch st2
	fabs
	faddp st1,st0		; |b| + sqrt(b^2 - 1)
	fyl2x
.10:	test ax,0x200
	fld qword [fpi2]
	mov eax,0x10000
       jz	.11
	fchs
.11:	fstp qword [edx+ecx*8]
	fstp qword [ebx+ecx*8]
	sub ecx,byte 1
	ffree st0
	ffree st1
       jns near	.1
	shr eax,16
	pop esi
	pop edi
	pop ebx
       retn
.12:	fpatan
       jmp	.11
.13:	fabs
       jp	.10		; inf
	fld st0
       jmp	.11		; nan
.14:	fxch			; real part
	fst st1
	fmul st0,st0
	cmp byte [edi+ecx*8+7],0
	fld1
	faddp st1,st0		; a^2 + 1
	fsqrt
	fldln2
	fxch st2
	faddp st1,st0		; |a| + sqrt(a^2 + 1)
	fyl2x
       jns	.15
	fchs
.15:	fldz
       jmp	.11
.16:	fld qword [edi+ecx*8]	; real
	fxam
	fnstsw ax
	sahf
       jbe	.17
	fld1
	fld st1
	fmul st0,st0
	test ax,0x200
	faddp st1,st0		; a^2 + 1
	fsqrt
	fldln2
	fxch st2
	fabs
	faddp st1,st0		; |a| + sqrt(a^2 + 1)
	fyl2x
       jz	.17
	fchs
.17:	fstp qword [ebx+ecx*8]
	sub ecx,byte 1
       jns	.16
	xor eax,eax
	pop esi
	pop edi
	pop ebx
       retn
