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
fcpi:	db	0x68,0x01,0x00,0x00,0x00,0x00,0x00,0x80,0xFF,0x3F	; real(pi)/double(pi)
align	8
f2pi:	db	0x18,0x2D,0x44,0x54,0xFB,0x21,0x19,0x40			; 2pi


[segment .text align=16]
global	_fcis
global	_fmcis
global	_fscis
global	_ftcis


;void fxcis(double* or, double* oi, const double* sr, const double* tr, int n)
;
_fmcis:
	push ebx
	push edi
	push esi
	fninit
	mov ecx,[esp+32]	; n
	mov esi,[esp+28]	; tr
	sub ecx,byte 1
	mov edi,[esp+24]	; sr
	fld tword [fcpi]
	mov edx,[esp+20]	; oi
	fldz
	mov ebx,[esp+16]	; or
	fld qword [f2pi]
.1:	fld qword [edi+ecx*8]
	fucomi st2
       jp	.7
       jz	.5
.2:	fprem
	fnstsw ax
	sahf
       jp	.2
	fmul st0,st3
	fsincos
.3:	fld qword [esi+ecx*8]
	fucomi st0
       jp	.6
	fmul st2,st0
	fmulp st1,st0
	fstp qword [ebx+ecx*8]
.4:	fstp qword [edx+ecx*8]
	sub ecx,byte 1
       jns	.1
	fninit
	pop esi
	pop edi
	pop ebx
       retn
.5:	fld1			; zero
       jmp	.3
.6:	fstp st1		; nan
	fstp st1
.7:	fst qword [ebx+ecx*8]
       jmp	.4


align	4

_fscis:
	push ebx
	push edi
	push esi
	fninit
	mov ecx,[esp+32]	; n
	mov esi,[esp+28]	; tr
	sub ecx,byte 1
	mov edi,[esp+24]	; sr
	fld qword [f2pi]
	mov edx,[esp+20]	; oi
	fld qword [edi]
	mov ebx,[esp+16]	; or
	fldz
	fucomip st1
       jp	.6
       jz	.4
.1:	fprem
	fnstsw ax
	sahf
       jp	.1
	fld tword [fcpi]
	fmulp st1,st0
	fsincos
.2:	fld qword [esi+ecx*8]
	fucomi st0
       jp	.5
	fld st0
	fmul st0,st2
	fstp qword [ebx+ecx*8]
	fmul st0,st2
.3:	fstp qword [edx+ecx*8]
	sub ecx,byte 1
       jns	.2
	fninit
	pop esi
	pop edi
	pop ebx
       retn
.4:	fld1
       jmp	.2
.5:	fst qword [ebx+ecx*8]
       jmp	.3
.6:	fst qword [ebx+ecx*8]
	fst qword [edx+ecx*8]
	sub ecx,byte 1
       jns	.6
	fninit
	pop esi
	pop edi
	pop ebx
       retn


align	4

_ftcis:
	push ebx
	push edi
	push esi
	fninit
	mov ecx,[esp+32]	; n
	mov esi,[esp+28]	; tr
	sub ecx,byte 1
	mov edi,[esp+24]	; sr
	fldz
	mov edx,[esp+20]	; oi
	fld qword [esi]
	mov ebx,[esp+16]	; or
	fucomi st1
       jp	.6
       jz	.6
	fld tword [fcpi]
	fld qword [f2pi]
.1:	fld qword [edi+ecx*8]
	fucomi st4
       jp	.5
       jz	.4
.2:	fprem
	fnstsw ax
	sahf
       jp	.2
	fmul st0,st2
	fsincos
	fmul st0,st4
	fstp qword [ebx+ecx*8]
	fmul st0,st3
.3:	fstp qword [edx+ecx*8]
	sub ecx,byte 1
       jns	.1
	fninit
	pop esi
	pop edi
	pop ebx
       retn
.4:	fstp qword [edx+ecx*8]
	fld st2
	fstp qword [ebx+ecx*8]
	sub ecx,byte 1
       jns	.1
	fninit
	pop esi
	pop edi
	pop ebx
       retn
.5:	fst qword [ebx+ecx*8]
       jmp	.3
.6:	fst qword [ebx+ecx*8]
	fst qword [edx+ecx*8]
	sub ecx,byte 1
       jns	.6
	fninit
	pop esi
	pop edi
	pop ebx
       retn


align	4

;void fcis(double* or, double* oi, const double* sr, int n)
;
_fcis:
	push ebx
	push edi
	fninit
	mov ecx,[esp+24]	; n
	mov edi,[esp+20]	; sr
	sub ecx,byte 1
	fld tword [fcpi]
	mov edx,[esp+16]	; oi
	fldz
	mov ebx,[esp+12]	; or
	fld qword [f2pi]
.1:	fld qword [edi+ecx*8]
	fucomi st2
       jp	.6
       jz	.5
.2:	fprem
	fnstsw ax
	sahf
       jp	.2
	fmul st0,st3
	fsincos
.3:	fstp qword [ebx+ecx*8]
.4:	fstp qword [edx+ecx*8]
	sub ecx,byte 1
       jns	.1
	fninit
	pop edi
	pop ebx
       retn
.5:	fld1
       jmp	.3
.6:	fst qword [ebx+ecx*8]
       jmp	.4
