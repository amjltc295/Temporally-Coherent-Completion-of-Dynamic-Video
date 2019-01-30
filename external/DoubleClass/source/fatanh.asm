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
fln4:	db	0xAC,0x79,0xCF,0xD1,0xF7,0x17,0x72,0xB1,0xFC,0xBF	; -ln(2)/4
align	4
f1o2:	dd	0x3F000000						; 1/2
fln2:	db	0xAC,0x79,0xCF,0xD1,0xF7,0x17,0x72,0xB1,0xFD,0xBF	; -ln(2)/2
align	4
f1n2:	dd	0xBF000000						; -1/2
fpi2:	db	0x18,0x2D,0x44,0x54,0xFB,0x21,0xF9,0x3F			; pi/2


[segment .text align=16]
global	_fatanh


;bool fatanh(double* or, double* oi, const double* sr, const double* si, int n)
;
_fatanh:
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
       jz near	.14
.1:	fld qword [edi+ecx*8]
	fxam
	fnstsw ax
	sahf
	fld qword [esi+ecx*8]
	fxam
	fnstsw ax
       jc near	.7
       jz	.4
	sahf
       jc near	.8
       jz near	.12
	fabs			; |b|
	fxch
	fabs			; |a|
	fld st1
	fadd st2,st0		; 2*|b|
	fmul st0,st0		; b^2
	test ax,0x200
	fld st1
	fadd st2,st0		; 2*|a|
	fmul st0,st0		; a^2
	faddp st1,st0
	fadd st1,st0		; a^2 + b^2 + 2*|a|
	fld1
	fadd st2,st0		; 1 + a^2 + b^2 + 2*|a|
	fsubrp st1,st0		; 1 - a^2 - b^2
	fld st2
	fld st1
	fpatan
	mov eax,0x10000
	fmul dword [f1o2]
       jz	.2
	fchs
.2:	fstp qword [edx+ecx*8]
	fmul st0,st0
	fxch st2
	fmul st0,st0
	cmp byte [edi+ecx*8+7],0
	faddp st2,st0
	fmul st0,st0
	fdivp st1,st0
	fld tword [fln4]
	fxch
	fyl2x
       jns	.3
	fchs
.3:	fstp qword [ebx+ecx*8]
	sub ecx,byte 1
       jns	.1
	shr eax,16
	pop esi
	pop edi
	pop ebx
       retn
.4:	sahf			; imaginary
       jc	.8
       jz	.5
	fld1
	fpatan
	mov eax,0x10000
.5:	fstp qword [edx+ecx*8]
.6:	fstp qword [ebx+ecx*8]
	sub ecx,byte 1
       jns	.1
	shr eax,16
	pop esi
	pop edi
	pop ebx
       retn
.7:    jnp	.10
	sahf
       jnc	.9
.8:    jnp	.11
.9:	test ax,0x200		; inf
	ffree st1
	fldz
	ffree st1
	fld qword [fpi2]
	mov eax,0x10000
       jz	.5
	fchs
       jmp	.5
.10:	fxch
.11:	fst qword [edx+ecx*8]	; nan
	fstp st1
       jmp	.6
.12:	fld1			; real
	fsub st0,st2		; 1 - a
	fld1
	faddp st3,st0		; 1 + a
	fdivrp st2,st0		; (1 - a)/(1 + a)
	fucomi st1
       jb	.13
	fld qword [fpi2]
	mov eax,0x10000
	fstp st1
.13:	fstp qword [edx+ecx*8]
	fldln2
	fxch
	fabs
	fyl2x
	fmul dword [f1n2]
	fstp qword [ebx+ecx*8]
	sub ecx,byte 1
       jns	.1
	shr eax,16
	pop esi
	pop edi
	pop ebx
       retn
.14:	fld qword [fpi2]	; real
	fld tword [fln2]
	mov eax,0x10000
.15:	fld qword [edi+ecx*8]
	fxam
	fnstsw ax
	sahf
       jc	.17
       jz	.18
	fld1
	fsub st0,st1
	fld1
	faddp st2,st0
	fdivrp st1,st0
	fld st1
	fldz
	fucomi st2
	fxch st2
	fabs
	fyl2x
	cmovnbe esi,eax
	fstp qword [ebx+ecx*8]
	fcmovnbe st2
.16:	fstp qword [edx+ecx*8]
	sub ecx,byte 1
       jns	.15
	mov eax,esi
	ffree st1
	pop esi
	ffree st0
	pop edi
	shr eax,16
	pop ebx
       retn
.17:   jnp	.18
	fldz			; inf
	fstp st1
	fstp qword [ebx+ecx*8]
	mov esi,eax
	fld st1
       jmp	.16
.18:	fst qword [ebx+ecx*8]	; nan,zero
       jmp	.16
