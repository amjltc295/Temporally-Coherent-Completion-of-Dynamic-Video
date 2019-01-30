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
global	_fmxor
global	_ftxor


;fxxor(double* or, const double* sr, const double* si, const double* tr, const double* ti, int n)
;
_fmxor:
	push ebx
	push edi
	push esi
	mov ecx,[esp+36]	; n
	mov esi,[esp+32]	; ti
	sub ecx,byte 1
	mov edi,[esp+28]	; tr
	mov eax,esi
	mov edx,[esp+24]	; si
	mov ebx,[esp+20]	; sr
	or eax,edx
	fld1
	mov eax,[esp+16]	; or
       jz	.2		; real
	test esi,esi
       jz	.3		; t real
	test edx,edx
       jz	.4		; s real
.1:	fld qword [ebx+ecx*8]
	fldz
	fld qword [edx+ecx*8]
	fucomip st2
	fcmovne st2
	fcmovu st2
	fxch
	fucomip st1
	fcmovne st1		; sa || sb
	fld qword [edi+ecx*8]
	fldz
	fld qword [esi+ecx*8]
	fucomip st2
	fcmovne st3
	fcmovu st3
	fxch
	fucomip st1
	fcmovne st2		; ta || tb
	fsubp st1,st0
	fabs			; xor(s,t)
	fstp qword [eax+ecx*8]
	sub ecx,byte 1
       jns	.1
	ffree st0
	pop esi
	pop edi
	pop ebx
       retn
.2:	fldz			; real
	fld qword [ebx+ecx*8]
	fucomip st1
	fcmovne st1
	fcmovu st1
	fldz
	fld qword [edi+ecx*8]
	fucomip st1
	fcmovne st2
	fcmovu st2
	fsubp st1,st0
	fabs
	fstp qword [eax+ecx*8]
	sub ecx,byte 1
       jns	.2
	ffree st0
	pop esi
	pop edi
	pop ebx
       retn
.3:	xchg ebx,edi		; t real
	xchg edx,esi
.4:	fldz			; s real
	fld qword [ebx+ecx*8]
	fucomip st1
	fcmovne st1
	fcmovu st1
	fld qword [edi+ecx*8]
	fldz
	fld qword [esi+ecx*8]
	fucomip st2
	fcmovne st3
	fcmovu st3
	fxch
	fucomip st1
	fcmovne st2
	fsubp st1,st0
	fabs
	fstp qword [eax+ecx*8]
	sub ecx,byte 1
       jns	.4
	ffree st0
	pop esi
	pop edi
	pop ebx
       retn


align	4

_ftxor:
	push ebx
	push edi
	push esi
	mov ecx,[esp+36]	; n
	mov esi,[esp+32]	; ti
	sub ecx,byte 1
	mov edi,[esp+28]	; tr
	test esi,esi
	mov edx,[esp+24]	; si
	fld1
	mov ebx,[esp+20]	; sr
	fld qword [edi]
	mov eax,[esp+16]	; or
	fldz
       jz	.1		; t real
	fld qword [esi]
	fucomip st2
	fcmovne st2
	fcmovu st2
.1:	fxch
	fucomip st1
	fcmovne st1
	fcmovu st1
	test edx,edx
       jz	.3		; s real
.2:	fld qword [ebx+ecx*8]
	fldz
	fld qword [edx+ecx*8]
	fucomip st2
	fcmovne st3
	fcmovu st3
	fxch
	fucomip st1
	fcmovne st2
	fsub st0,st1
	fabs
	fstp qword [eax+ecx*8]
	sub ecx,byte 1
       jns	.2
	ffree st1
	pop esi
	ffree st0
	pop edi
	pop ebx
       retn
.3:	fldz			; s real
	fld qword [ebx+ecx*8]
	fucomip st1
	fcmovne st2
	fcmovu st2
	fsub st0,st1
	fabs
	fstp qword [eax+ecx*8]
	sub ecx,byte 1
       jns	.3
	ffree st1
	pop esi
	ffree st0
	pop edi
	pop ebx
       retn
