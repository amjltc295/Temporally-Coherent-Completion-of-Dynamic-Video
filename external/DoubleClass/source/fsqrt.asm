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
f1o2:	dd	0x3F000000						; 1/2
fnan:	dd	0xFFC00000						; nan


[segment .text align=16]
global	_fsqrt


;bool fsqrt(void* or, void* oi, const void* sr, const void* si, int n)
;
_fsqrt:
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
       jc near	.5
       jz near	.9
	sahf
       jc near	.11
       jz near	.12
	or eax,0x10000
	fld st1
	cmp byte [edi+ecx*8+7],0
	fmul st0,st0		; a^2
	fld st1
	fmul st0,st0		; b^2
	faddp st1,st0
	fsqrt			; |x|
       js	.3
	faddp st2,st0		; |x| + a
	fmul dword [f1o2]
	fxch
	fmul dword [f1o2]
	fsqrt
	fst qword [ebx+ecx*8]
	fdivp st1,st0
.2:	fstp qword [edx+ecx*8]
	sub ecx,byte 1
       jns	.1
	shr eax,16
	pop esi
	pop edi
	pop ebx
       retn
.3:	test ax,0x200		; negative
	fsubrp st2,st0		; |x| - a
	fmul dword [f1o2]
	fxch
	fmul dword [f1o2]
	fsqrt
       jz	.4
	fchs
.4:	fst qword [edx+ecx*8]
	fdivp st1,st0
	fabs
	fstp qword [ebx+ecx*8]
	sub ecx,byte 1
       jns	.1
	shr eax,16
	pop esi
	pop edi
	pop ebx
       retn
.5:	ffree st0		; affine
	fincstp
       jnp	.8
	sahf
	fabs
       jc	.7
	cmp byte [edi+ecx*8+7],0
	fldz
       jns	.6
	fxch
	mov eax,0x10000
.6:	fstp qword [edx+ecx*8]
	fstp qword [ebx+ecx*8]
	sub ecx,byte 1
       jns	.1
	shr eax,16
	pop esi
	pop edi
	pop ebx
       retn
.7:	fld dword [fnan]	; nan
	fstp st1
.8:	fst qword [ebx+ecx*8]
       jmp	.2
.9:	test ax,0x4000		; a == 0
	fstp st1
       jnz	.10		; x == 0
	fabs
	fmul dword [f1o2]
	fsqrt
	test ax,0x200
	mov eax,0x10000
.10:	fst qword [ebx+ecx*8]
       jz	.2
	fchs
       jmp	.2
.11:	fst st1			; affine
	fabs
	fstp qword [ebx+ecx*8]
       jnp	.2		; nan
	mov eax,0x10000
       jmp	.2		; inf
.12:	fxch			; b == 0
	fabs
	fsqrt
	cmp byte [edi+ecx*8+7],0
       jns	.13
	fxch
	mov eax,0x10000
.13:	fstp qword [ebx+ecx*8]
       jmp	.2
.14:	fld qword [edi+ecx*8]	; real
	fxam
	fnstsw ax
	sahf
	fabs
       jc	.18
	fsqrt
.15:	test ax,0x200
	fldz
       jz	.16
	fxch
	mov esi,1
.16:	fstp qword [edx+ecx*8]
.17:	fstp qword [ebx+ecx*8]
	sub ecx,byte 1
       jns	.14
	mov eax,esi
	pop esi
	pop edi
	pop ebx
       retn
.18:   jp	.15
	fst qword [edx+ecx*8]
       jmp	.17
