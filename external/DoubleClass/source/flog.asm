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
flim:	dd	0x44000000						; 2^9
fpi2:	db	0x18,0x2D,0x44,0x54,0xFB,0x21,0xF9,0x3F			; pi/2


[segment .text align=16]
global	_flog


;bool flog(double* or, double* oi, const double* sr, const double* si, int n)
;
_flog:
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
	fldz
	mov ebx,[esp+16]	; or
       jz near	.12
	fld tword [fln2]
.1:	fld qword [esi+ecx*8]
	fucomi st2
       jp near	.11
	fld qword [edi+ecx*8]
       jz	.7
	fucomi st3
       jp near	.10
       jz	.8
	fld st2
	fld st2
	fmul st0,st0
	fld st2
	fmul st0,st0
	fld st1
	fmul dword [flim]
	fucomip st1
       jb	.5
	fld st0
	fmul dword [flim]
	fucomip st2
       jb	.6
	faddp st1,st0
	fyl2x
.2:	fstp qword [ebx+ecx*8]
	fpatan
.3:	mov eax,0x10000
.4:	fstp qword [edx+ecx*8]
	sub ecx,byte 1
       jns	.1
	shr eax,16
	ffree st1
	pop esi
	ffree st0
	pop edi
	pop ebx
       retn
.5:	fdivp st1,st0		; a^2 >> b^2
	fyl2xp1
	fldln2
	fld st2
	fabs
	fyl2x
	faddp st1,st0
       jmp	.2
.6:	fdivrp st1,st0		; b^2 >> a^2
	fyl2xp1
	fldln2
	fld st3
	fabs
	fyl2x
	faddp st1,st0
       jmp	.2
.7:	fucomi st3		; b == 0
       jp	.10
	fldln2
	fxch
	fabs
	fyl2x
	fstp qword [ebx+ecx*8]
       jnb	.4
	fldpi
	fstp st1
       jmp	.3
.8:	fucomip st1		; a == 0
	fabs
	fldln2
	fxch
	fld qword [fpi2]
       jb	.9
	fchs
.9:	fstp qword [edx+ecx*8]
	fyl2x
	mov eax,0x10000
	fstp qword [ebx+ecx*8]
	sub ecx,byte 1
       jns	.1
	mov eax,1
	ffree st1
	pop esi
	ffree st0
	pop edi
	pop ebx
       retn
.10:	fstp st1		; nan
.11:	fst qword [ebx+ecx*8]
       jmp	.4
.12:	add esi,byte 1		; real
.13:	fldln2
	fld qword [edi+ecx*8]
	fucomi st2
	fabs
       jp	.15
	fyl2x
	cmovb eax,esi
	fstp qword [ebx+ecx*8]
	fldpi
	fcmovnb st1
.14:	fstp qword [edx+ecx*8]
	sub ecx,byte 1
       jns	.13
	ffree st0
	pop esi
	pop edi
	pop ebx
       retn
.15:	fst qword [ebx+ecx*8]	; nan
	fstp st1
       jmp	.14
