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
fnan:	dd	0xFFC00000						; nan


[segment .text align=16]
global	_fsign


;void fsign(double* or, double* oi, const double* sr, const double* si, int n)
;
_fsign:
	push ebx
	push edi
	push esi
	fninit
	mov ecx,[esp+32]	; n
	mov esi,[esp+28]	; si
	sub ecx,byte 1
	mov edi,[esp+24]	; sr
	test esi,esi
	fld1
	mov edx,[esp+20]	; oi
	fchs
	mov ebx,[esp+16]	; or
	fldz
	fld1
       jz near	.10
.1:	fld qword [edi+ecx*8]
	fucomi st2
	fld qword [esi+ecx*8]
       jp	.5
       jz	.3
	lahf
	fucomi st3
	fxam
       jp	.6
       jz	.4
	fnstsw ax
	fld st1
	sahf
	fxam
	fnstsw ax
       jc	.7
	sahf
       jc	.9
	fmul st0,st0
	fld st1
	fmul st0,st0
	faddp st1,st0
	fsqrt
	fdivr st0,st3
	fmul st1,st0
	fmulp st2,st0
.2:	fstp qword [edx+ecx*8]
	fstp qword [ebx+ecx*8]
	sub ecx,byte 1
       jns	.1
	fninit
	pop esi
	pop edi
	pop ebx
       retn
.3:	fucomi st3
       jp	.6
	fcmovb st4
	fcmovnbe st2
       jmp	.2
.4:	sahf
	fincstp
	fcmovb st3
	fcmovnbe st1
	fdecstp
       jmp	.2
.5:	fxch			; nan
.6:	fst st1
       jmp	.2
.7:	ffree st0
	sahf
	fincstp
       jc	.8
	fucomi st3		; im == inf
	fldz
	fstp st2
	fcmovb st4
	fcmovnbe st2
       jmp	.2
.8:	fld dword [fnan]	; nan
	fst st2
	fstp st1
       jmp	.2
.9:	fucomip st4		; re == inf
	ffree st0
	fincstp
	fcmovb st3
	fcmovnbe st1
	fldz
       jmp	.2
.10:	fld qword [edi+ecx*8]
	fucomi st2
       jp	.11
	fcmovb st3
	fcmovnbe st1
.11:	fstp qword [ebx+ecx*8]
	sub ecx,byte 1
       jns	.10
	fninit
	pop esi
	pop edi
	pop ebx
       retn
