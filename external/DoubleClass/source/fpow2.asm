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
align	4
fnan:	dd	0xFFC00000						; nan
f2pi:	db	0x18,0x2D,0x44,0x54,0xFB,0x21,0x19,0x40			; 2pi
finf:	dd	0x7F800000						; inf


[segment .text align=16]
global	_fpow2
global	_fmscale
global	_fsscale
global	_ftscale


;>>	st0 = R		[finite]
;
;[st0..2,eax]
;
;<<	st0 = 2^R
;
_rpow:
	sub esp,byte 16
	fist dword [esp]
	mov dword [esp+4],0
	mov dword [esp+8],0x80000000
	fisub dword [esp]
	pop eax
	add eax,0x3FFF
	mov [esp+8],eax
       jle	.1
	cmp eax,0x8000
       jge	.2
	f2xm1
	fld1
	faddp st1,st0
	fld tword [esp]
	add esp,byte 12
	fmulp st1,st0
       retn
.1:	fldz
	fstp st1
	add esp,byte 12
       retn
.2:	fld dword [finf]
	add esp,byte 12
	fstp st1
       retn


;void fpow2(double* or, double* oi, const double* sr, const double* si, int n)
;
_fpow2:
	push ebx
	push edi
	push esi
	push ebp
	fninit
	mov ebp,esp
	mov ecx,[esp+36]	; n
	and esp,0xFFFFFFF0
	mov esi,[ebp+32]	; si
	sub ecx,byte 1
	mov edi,[ebp+28]	; sr
	test esi,esi
	mov edx,[ebp+24]	; oi
	mov ebx,[ebp+20]	; or
       jz	.12
	fldln2
	fld tword [fcpi]
	fld qword [f2pi]
.1:	fld qword [esi+ecx*8]
	fxam
	fnstsw ax
	sahf
       jc	.7
       jz	.8
	fmul st0,st3
.2:	fprem
	fnstsw ax
	sahf
       jp	.2
	fmul st0,st2
	fsincos
.3:	fld qword [edi+ecx*8]
	fxam
	fnstsw ax
	sahf
       jc	.9
       jz	.11
       call	_rpow
.4:	fmul st2,st0
	fmulp st1,st0
.5:	fstp qword [ebx+ecx*8]
	fstp qword [edx+ecx*8]
	sub ecx,byte 1
       jns	.1
	mov esp,ebp
	fninit
	pop ebp
	pop esi
	pop edi
	pop ebx
       retn
.7:	fld dword [fnan]
	fst st1
       jmp	.3
.8:	fld1
       jmp	.3
.9:    jnp	.10		; nan
	test ax,0x200
       jz	.4		; inf
	fldz
	fstp st1
.10:	fst st2
	fstp st1
       jmp	.5
.11:	ffree st0
	fincstp
       jmp	.5
.12:	fld1			; real
	fldz
.13:	fld qword [edi+ecx*8]
	fxam
	fnstsw ax
	sahf
       jc	.15
	fcmove st2
       jz	.14
       call	_rpow
.14:	fstp qword [ebx+ecx*8]
	sub ecx,byte 1
       jns	.13
	mov esp,ebp
	pop ebp
	ffree st1
	pop esi
	ffree st0
	pop edi
	pop ebx
       retn
.15:   jnp	.14		; nan
	test ax,0x200
	fcmovne st1
       jmp	.14		; inf


align	4

;void fmscale(double* or, const double* sr, const double* tr, int n)
;
_fmscale:
	push ebx
	fninit
	mov ecx,[esp+20]	; n
	mov edx,[esp+16]	; tr
	sub ecx,byte 1
	mov eax,[esp+12]	; sr
	mov ebx,[esp+8]		; or
.1:	fld qword [edx+ecx*8]
	fld qword [eax+ecx*8]
	fscale
	fstp qword [ebx+ecx*8]
	sub ecx,byte 1
	ffree st0
       jns	.1
	pop ebx
       retn


align	4

_fsscale:
	push ebx
	fninit
	mov ecx,[esp+20]	; n
	mov edx,[esp+16]	; tr
	sub ecx,byte 1
	mov eax,[esp+12]	; sr
	mov ebx,[esp+8]		; or
	fld qword [eax]
.1:	fld qword [edx+ecx*8]
	fld st1
	fscale
	fstp qword [ebx+ecx*8]
	sub ecx,byte 1
	ffree st0
	fincstp
       jns	.1
	ffree st0
	pop ebx
       retn


align	4

_ftscale:
	push ebx
	fninit
	mov ecx,[esp+20]	; n
	mov edx,[esp+16]	; tr
	sub ecx,byte 1
	mov eax,[esp+12]	; sr
	mov ebx,[esp+8]		; or
	fld qword [edx]
.1:	fld qword [eax+ecx*8]
	fscale
	fstp qword [ebx+ecx*8]
	sub ecx,byte 1
       jns	.1
	ffree st0
	pop ebx
       retn
