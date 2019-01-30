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

[segment .text align=16]
global	_fmmod
global	_fsmod
global	_ftmod


;void fxmod(double* or, const double* sr, const double* tr, int n)
;
_fmmod:
	push ebx
	push edi
	push esi
	fninit
	mov ecx,[esp+28]	; n
	mov esi,[esp+24]	; tr
	sub ecx,byte 1
	mov edi,[esp+20]	; sr
	mov ebx,[esp+16]	; or
	fldz
.1:	fld qword [esi+ecx*8]
	fucomi st1
       jp	.5
	fld qword [edi+ecx*8]
       jz	.3
	fucomi st2
       jp	.3
       jz	.3
	mov dl,[esi+ecx*8+7]
.2:	fprem
	fnstsw ax
	sahf
       jp	.2
	fucomi st2
       jz	.3
	xor dl,[edi+ecx*8+7]
       js	.4
.3:	fstp qword [ebx+ecx*8]
	sub ecx,byte 1
	ffree st0
	fincstp
       jns	.1
	ffree st0
	pop esi
	pop edi
	pop ebx
       retn
.4:	faddp st1,st0
.5:	fstp qword [ebx+ecx*8]
	sub ecx,byte 1
       jns	.1
	ffree st0
	pop esi
	pop edi
	pop ebx
       retn


align	4

_fsmod:
	push ebx
	push edi
	push esi
	fninit
	mov ecx,[esp+28]	; n
	mov esi,[esp+24]	; tr
	sub ecx,byte 1
	mov edi,[esp+20]	; sr
	fldz
	mov ebx,[esp+16]	; or
	fld qword [edi]
	fucomi st1
       jp	.5
       jz	.5
	mov dx,[edi+6]
.1:	fld qword [esi+ecx*8]
	fucomi st2
       jp	.3
       jz	.3
	fld st1
	mov dl,[esi+ecx*8+7]
.2:	fprem
	fnstsw ax
	sahf
       jp	.2
	fucomi st3
       jz	.4
	xor dl,dh
       jns	.4
	faddp st1,st0
.3:	fstp qword [ebx+ecx*8]
	sub ecx,byte 1
       jns	.1
	ffree st1
	pop esi
	ffree st0
	pop edi
	pop ebx
       retn
.4:	fstp qword [ebx+ecx*8]
	sub ecx,byte 1
	ffree st0
	fincstp
       jns	.1
	ffree st1
	pop esi
	ffree st0
	pop edi
	pop ebx
       retn
.5:	fst qword [ebx+ecx*8]
	sub ecx,byte 1
       jns	.5
	ffree st1
	pop esi
	ffree st0
	pop edi
	pop ebx
       retn


align	4

_ftmod:
	push ebx
	push edi
	push esi
	fninit
	mov ecx,[esp+28]	; n
	mov esi,[esp+24]	; tr
	sub ecx,byte 1
	fldz
	mov edi,[esp+20]	; sr
	fld qword [esi]
	mov ebx,[esp+16]	; or
	fucomi st1
       jp	.5
       jz	.4
	mov dx,[esi+6]
.1:	fld qword [edi+ecx*8]
	fucomi st2
       jp	.3
       jz	.3
	mov dl,[edi+ecx*8+7]
.2:	fprem
	fnstsw ax
	sahf
       jp	.2
	fucomi st2
       jz	.3
	xor dl,dh
       jns	.3
	fadd st0,st1
.3:	fstp qword [ebx+ecx*8]
	sub ecx,byte 1
       jns	.1
	ffree st1
	pop esi
	ffree st0
	pop edi
	pop ebx
       retn
.4:	fld qword [edi+ecx*8]
	fstp qword [ebx+ecx*8]
	sub ecx,byte 1
       jns	.4
	ffree st1
	pop esi
	ffree st0
	pop edi
	pop ebx
       retn
.5:	fst qword [ebx+ecx*8]
	sub ecx,byte 1
       jns	.5
	ffree st1
	pop esi
	ffree st0
	pop edi
	pop ebx
       retn
