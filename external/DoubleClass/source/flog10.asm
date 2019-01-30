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
flg1:	db	0x96,0x71,0x28,0x37,0xA9,0xD8,0x5B,0xDE,0xFD,0x3F	; 1/ln(10)
align	4
flim:	dd	0x44000000						; 2^9
fpi1:	db	0xA1,0xFB,0xB2,0x4C,0x7C,0xD4,0xF5,0x3F			; pi/ln(10)
fpi2:	db	0xA1,0xFB,0xB2,0x4C,0x7C,0xD4,0xE5,0x3F			; pi/2ln(10)
flg2:	db	0x99,0xF7,0xCF,0xFB,0x84,0x9A,0x20,0x9A,0xFC,0x3F	; lg(2)/2


[segment .text align=16]
global	_flog10


;bool flog10(double* or, double* oi, const double* sr, const double* si, int n)
;
_flog10:
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
       jz near	.12
	fld tword [flg1]
	fld tword [flg2]
.1:	fld qword [esi+ecx*8]
	fldz
	fucomip st1
       jp near	.11
	fld qword [edi+ecx*8]
       jz	.7
	fldz
	fucomip st1
       jp near	.10
       jz near	.8
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
	fmul st0,st2
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
	fldlg2
	fld st2
	fabs
	fyl2x
	faddp st1,st0
       jmp	.2
.6:	fdivrp st1,st0		; b^2 >> a^2
	fyl2xp1
	fldlg2
	fld st3
	fabs
	fyl2x
	faddp st1,st0
       jmp	.2
.7:	fldz
	fucomip st1		; b == 0
       jp	.10
	fldlg2
	fxch
	fabs
	fyl2x
	fstp qword [ebx+ecx*8]
       jb	.4
	fld qword [fpi1]
	fstp st1
       jmp	.3
.8:	fucomip st1		; a == 0
	fabs
	fldlg2
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
.12:	fldz
	fld qword [fpi1]	; real
	add esi,byte 1
.13:	fldlg2
	fld qword [edi+ecx*8]
	fucomi st3
	fabs
       jp	.15
	fyl2x
	cmovb eax,esi
	fstp qword [ebx+ecx*8]
	fldz
	fcmovb st1
.14:	fstp qword [edx+ecx*8]
	sub ecx,byte 1
       jns	.13
	ffree st1
	pop esi
	ffree st0
	pop edi
	pop ebx
       retn
.15:	fst qword [ebx+ecx*8]	; nan
	fstp st1
       jmp	.14
