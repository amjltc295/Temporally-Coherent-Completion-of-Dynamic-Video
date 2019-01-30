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
f1o2:	dd	0x3F000000						; 1/2
f2pi:	db	0x18,0x2D,0x44,0x54,0xFB,0x21,0x19,0x40			; 2pi
fnan:	dd	0xFFC00000						; nan


[segment .text align=16]
extern	_rexp
global	_fcosh


;void fcosh(double* or, double* oi, const double* sr, const double* si, int n)
;
_fcosh:
	push ebx
	push edi
	push esi
	push ebp
	fninit
	mov ecx,[esp+36]	; n
	mov ebp,esp
	mov esi,[esp+32]	; si
	and esp,0xFFFFFFF0
	sub ecx,byte 1
	mov edi,[ebp+28]	; sr
	test esi,esi
	mov edx,[ebp+24]	; oi
	mov ebx,[ebp+20]	; or
       jz near	.13
	fld tword [fcpi]
	fld qword [f2pi]
.1:	fld qword [esi+ecx*8]
	fxam
	fnstsw ax
	sahf
       jc	.8
       jz	.10
.2:	fprem
	fnstsw ax
	sahf
       jp	.2
	fmul st0,st2
	fld qword [edi+ecx*8]
	fxam
	fnstsw ax
	sahf
       jc	.7
       jz	.6
       call	_rexp		; exp(a)
	fld st0
	fld1
	fdiv st0,st1		; exp(-a)
	fsub st2,st0		; exp(a) - exp(-a)
	faddp st1,st0		; exp(a) + exp(-a)
.4:	fxch st2
	fsincos
	fmulp st3,st0
	fmulp st1,st0
	fld dword [f1o2]
	fmul st2,st0
	fmulp st1,st0
.5:	fstp qword [edx+ecx*8]
	fstp qword [ebx+ecx*8]
	sub ecx,byte 1
       jns	.1
	mov esp,ebp
	pop ebp
	ffree st1
	pop esi
	ffree st0
	pop edi
	pop ebx
       retn
.6:	fstp qword [edx+ecx*8]	; imaginary
	fcos
	fstp qword [ebx+ecx*8]
	sub ecx,byte 1
       jns	.1
	mov esp,ebp
	pop ebp
	ffree st1
	pop esi
	ffree st0
	pop edi
	pop ebx
       retn
.7:    jnp	.9
	fld st0
	fabs
       jmp	.4		; inf
.8:	fld dword [fnan]
.9:	fst st1
       jmp	.5		; nan
.10:	fld qword [edi+ecx*8]	; real
	fxam
	fnstsw ax
	sahf
       jc	.7
       jz	.12
       call	_rexp		; exp(a)
	fld1
	fdiv st0,st1		; exp(-a)
	faddp st1,st0		; exp(a) + exp(-a)
	fmul dword [f1o2]
.11:	fstp qword [ebx+ecx*8]
	fstp qword [edx+ecx*8]
	sub ecx,byte 1
       jns	.1
	mov esp,ebp
	pop ebp
	ffree st1
	pop esi
	ffree st0
	pop edi
	pop ebx
       retn
.12:	fld1
	fstp st1
       jmp	.11
.13:	fld qword [edi+ecx*8]	; real
	fxam
	fnstsw ax
	sahf
       jc	.15
       jz	.16
       call	_rexp		; exp(a)
	fld1
	fdiv st0,st1		; exp(-a)
	faddp st1,st0		; exp(a) + exp(-a)
	fmul dword [f1o2]
.14:	fstp qword [ebx+ecx*8]
	sub ecx,byte 1
	ffree st0
       jns	.13
	mov esp,ebp
	pop ebp
	pop esi
	pop edi
	pop ebx
       retn
.15:	fabs
       jmp	.14
.16:	fld1
       jmp	.14
