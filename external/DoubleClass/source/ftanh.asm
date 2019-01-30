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

;	The hyperbolic tangent can be accurately evaluated up to
;	a real part |R| < 373. |R| beyond that value causes an
;	overflow of the subexpression "exp(2R)" towards infinity.
;
;	MATLAB computes accurately for |R| < 20.


[segment .data align=16]
fcpi:	db	0x68,0x01,0x00,0x00,0x00,0x00,0x00,0x80,0xFF,0x3F	; real(pi)/double(pi)
align	4
f4d0:	dd	0x40800000						; 4
f2pi:	db	0x18,0x2D,0x44,0x54,0xFB,0x21,0x19,0x40			; 2pi
fnan:	dd	0xFFC00000						; nan


[segment .text align=16]
extern	_rexp
global	_ftanh


;void ftanh(double* or, double* oi, const double* sr, const double* si, int n)
;
_ftanh:
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
       jz near	.9
	fld qword [f2pi]
.1:	mov eax,[edi+ecx*8+4]
	rol eax,1
	cmp eax,0x80EEA000
       ja near	.5		; inf,nan,overflow
	fld qword [esi+ecx*8]
	fxam
	fnstsw ax
	sahf
       jc near	.6		; inf,nan
       jz near	.8
.2:	fprem
	fnstsw ax
	sahf
       jp	.2
	fld tword [fcpi]
	fmulp st1,st0
	fsincos
	fld qword [edi+ecx*8]
	fldz
	fucomip st1
       jz	.3
	fadd st0,st0
       call	_rexp		; exp(2a)
	fld st0
	fld1
	fadd st1,st0		; exp(2a) + 1
	fsubr st0,st2		; exp(2a) - 1
	fld st4
	fmul st0,st1
	fmul st0,st0
	fld st4
	fmul st0,st3
	fmul st0,st0
	faddp st1,st0		; n = ((exp(2a)+1)cos(b))^2 + ((exp(2a)-1)sin(b))^2
	fld1
	fdivrp st1,st0
	fmul st5,st0
	fmulp st2,st0
	fmulp st1,st0		; (exp(2a)+1)(exp(2a)-1)/n
	fstp qword [ebx+ecx*8]
	fmulp st1,st0
	fmul dword [f4d0]
	fmulp st1,st0		; 4exp(2a)cos(b)sin(b)/n
	fstp qword [edx+ecx*8]
	sub ecx,byte 1
       jns	.1
	mov esp,ebp
	pop ebp
	ffree st0
	pop esi
	pop edi
	pop ebx
       retn
.3:	fxch st2
	fdivrp st1,st0
	fstp qword [edx+ecx*8]
.4:	fstp qword [ebx+ecx*8]
	sub ecx,byte 1
       jns	.1
	mov esp,ebp
	pop ebp
	ffree st0
	pop esi
	pop edi
	pop ebx
       retn
.5:	cmp eax,0xFFF00000
       jnc	.7
	test al,1
	fldz
	fstp qword [edx+ecx*8]
	fld1
       jz	.4
	fchs
       jmp	.4
.6:	ffree st0
	fincstp
.7:	fld dword [fnan]	; nan
	fst qword [edx+ecx*8]
       jmp	.4
.8:	fstp qword [edx+ecx*8]	; real
	fld qword [edi+ecx*8]
	fadd st0,st0
       call	_rexp		; exp(2b)
	fld st0
	fld1
	fadd st1,st0		; exp(2b) + 1
	fsubp st2,st0		; exp(2b) - 1
	fdivp st1,st0
	fstp qword [ebx+ecx*8]
	sub ecx,byte 1
       jns	.1
	mov esp,ebp
	pop ebp
	ffree st0
	pop esi
	pop edi
	pop ebx
       retn
.9:	fld qword [edi+ecx*8]	; real
	fxam
	fnstsw ax
	sahf
       jc	.11
       jz	.10
	mov ax,[edi+ecx*8+6]
	rol ax,1
	fadd st0,st0
	cmp ax,0x8068
       jnc	.12
       call	_rexp
	fld st0
	fld1
	fadd st1,st0		; exp(2a) + 1
	fsubp st2,st0		; exp(2a) - 1
	fdivp st1,st0
.10:	fstp qword [ebx+ecx*8]
	sub ecx,byte 1
       jns	.9
	mov esp,ebp
	pop ebp
	pop esi
	pop edi
	pop ebx
       retn
.11:   jnp	.10
	shr ax,9
.12:	test al,1
	fld1
	fstp st1
       jz	.10
	fchs
       jmp	.10
