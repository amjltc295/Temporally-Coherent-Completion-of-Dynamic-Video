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
mcsr:	dd	0x9F80


[segment .text align=16]
global	_fxinit
global	_fmtimes			; vector'* vector
global	_fstimes			; scalar * matrix
global	_fvtimes			; vector * vector'


;void fxinit(void)
;
_fxinit:
	ldmxcsr [mcsr]
       retn


align	4

;void fmtimes(double* or, double* oi, const double* sr, const double* si, const double* tr, const double* ti, int k)
;
_fmtimes:
	push ebp
	push ebx
	push edi
	push esi
	ldmxcsr [mcsr]
	mov ebp,[esp+44]	; k
	mov edx,[esp+40]	; ti
	mov ecx,[esp+36]	; tr
	mov ebx,[esp+32]	; si
	mov eax,[esp+28]	; sr
	mov esi,[esp+24]	; oi
	mov edi,[esp+20]	; or
	test esi,esi
       jz near	.6
	test ebx,ebx
       jz near	.11
	test edx,edx
       jz near	.12
	sar ebp,1		; complex
	lea ebp,[ebp*2]
	xorps xmm0,xmm0
	xorps xmm1,xmm1
       jnc	.1
	movsd xmm0,[eax+ebp*8]
	movsd xmm2,[ebx+ebp*8]
	movsd xmm1,[ecx+ebp*8]
	movsd xmm3,[edx+ebp*8]
	movaps xmm4,xmm0
	mulsd xmm0,xmm1		; a*c
	mulsd xmm1,xmm2		; b*c
	mulsd xmm2,xmm3		; b*d
	mulsd xmm3,xmm4		; a*d
	subsd xmm0,xmm2		; a*c - b*d
	addsd xmm1,xmm3		; b*c + a*d
.1:	sub ebp,byte 2
       js	.3
.2:	movups xmm2,[eax+ebp*8]
	movups xmm4,[ebx+ebp*8]
	movups xmm3,[ecx+ebp*8]
	movups xmm5,[edx+ebp*8]
	sub ebp,byte 2
	movaps xmm6,xmm2
	mulpd xmm2,xmm3		; a*c
	mulpd xmm3,xmm4		; b*c
	addpd xmm0,xmm2
	mulpd xmm4,xmm5		; b*d
	addpd xmm1,xmm3
	mulpd xmm5,xmm6		; a*d
	subpd xmm0,xmm4
	addpd xmm1,xmm5
       jns	.2
.3:	movhlps xmm2,xmm0
	movhlps xmm3,xmm1
	addsd xmm0,xmm2
	addsd xmm1,xmm3
	movsd [edi],xmm0
	movsd [esi],xmm1
	pop esi
	pop edi
	pop ebx
	pop ebp
       retn
.6:	sar ebp,1		; o real
	lea ebp,[ebp*2]
	xorps xmm0,xmm0
       jnc	.7
	movsd xmm0,[eax+ebp*8]
	movsd xmm1,[ecx+ebp*8]
.7:	mulsd xmm0,xmm1
	sub ebp,byte 2
       js	.9
.8:	movups xmm1,[eax+ebp*8]
	movups xmm2,[ecx+ebp*8]
	sub ebp,byte 2
	mulpd xmm1,xmm2
	addpd xmm0,xmm1
       jns	.8
.9:	movhlps xmm1,xmm0
	addsd xmm0,xmm1
	movsd [edi],xmm0
	pop esi
	pop edi
	pop ebx
	pop ebp
       retn
.11:	xchg eax,ecx		; s real
	mov ebx,edx
.12:	sar ebp,1		; t real
	lea ebp,[ebp*2]
	xorps xmm0,xmm0
	xorps xmm1,xmm1
       jnc	.13
	movsd xmm0,[eax+ebp*8]
	movsd xmm1,[ebx+ebp*8]
	movsd xmm2,[ecx+ebp*8]
	mulsd xmm0,xmm2
	mulsd xmm1,xmm2
.13:	sub ebp,byte 2
       js	.3
.14:	movups xmm2,[eax+ebp*8]
	movups xmm3,[ecx+ebp*8]
	movups xmm4,[ebx+ebp*8]
	sub ebp,byte 2
	mulpd xmm2,xmm3
	mulpd xmm4,xmm3
	addpd xmm0,xmm2
	addpd xmm1,xmm4
       jns	.14
       jmp	.3


align	4

;void fstimes(double* or, double* oi, const double* sr, const double* si, const double* tr, const double* ti, int n)
;
_fstimes:
	push ebx
	push edi
	push esi
	ldmxcsr [mcsr]
	mov ecx,[esp+40]		; n
	mov ebx,[esp+20]		; oi
	sub ecx,byte 1
	mov eax,[esp+16]		; or
	test ebx,ebx
	mov edx,[esp+24]		; sr
	mov edi,[esp+32]		; tr
	movsd xmm0,[edx]
	mov edx,[esp+28]		; si
	movlhps xmm0,xmm0
       jz near	.3
	test edx,edx
	mov esi,[esp+36]		; ti
       jz near	.5
	movsd xmm1,[edx]
	test esi,esi
	movlhps xmm1,xmm1
       jz near	.7
.1:	sar ecx,1			; complex
	lea ecx,[ecx*2]
       jc	.2
	movsd xmm2,[edi+ecx*8]
	movsd xmm4,xmm2
	movsd xmm3,[esi+ecx*8]
	movsd xmm5,xmm3
	mulsd xmm4,xmm0
	mulsd xmm5,xmm1
	mulsd xmm2,xmm1
	mulsd xmm3,xmm0
	subsd xmm4,xmm5
	addsd xmm2,xmm3
	movsd [eax+ecx*8],xmm4
	movsd [ebx+ecx*8],xmm2
	sub ecx,byte 2
       js	.0
.2:	movups xmm2,[edi+ecx*8]
	movaps xmm4,xmm2
	movups xmm3,[esi+ecx*8]
	movaps xmm5,xmm3
	mulpd xmm4,xmm0
	mulpd xmm5,xmm1
	mulpd xmm2,xmm1
	mulpd xmm3,xmm0
	subpd xmm4,xmm5
	addpd xmm2,xmm3
	movups [eax+ecx*8],xmm4
	movups [ebx+ecx*8],xmm2
	sub ecx,byte 2
       jns	.2
	pop esi
	pop edi
	pop ebx
       retn
.3:	sar ecx,1			; o real
	lea ecx,[ecx*2]
       jc	.4
	movsd xmm1,[edi+ecx*8]
	mulsd xmm1,xmm0
	movsd [eax+ecx*8],xmm1
	sub ecx,byte 2
       js	.0
.4:	movups xmm1,[edi+ecx*8]
	mulpd xmm1,xmm0
	movups [eax+ecx*8],xmm1
	sub ecx,byte 2
       jns	.4
.0:	pop esi
	pop edi
	pop ebx
       retn
.5:	sar ecx,1			; s real
	lea ecx,[ecx*2]
       jc	.6
	movsd xmm1,[edi+ecx*8]
	mulsd xmm1,xmm0
	movsd xmm2,[esi+ecx*8]
	mulsd xmm2,xmm0
	movsd [eax+ecx*8],xmm1
	movsd [ebx+ecx*8],xmm2
	sub ecx,byte 2
       js	.0
.6:	movups xmm1,[edi+ecx*8]
	mulpd xmm1,xmm0
	movups xmm2,[esi+ecx*8]
	mulpd xmm2,xmm0
	movups [eax+ecx*8],xmm1
	movups [ebx+ecx*8],xmm2
	sub ecx,byte 2
       jns	.6
	pop esi
	pop edi
	pop ebx
       retn
.7:	sar ecx,1			; t real
	lea ecx,[ecx*2]
       jc	.8
	movsd xmm2,[edi+ecx*8]
	movsd xmm3,xmm2
	mulsd xmm2,xmm0
	mulsd xmm3,xmm1
	movsd [eax+ecx*8],xmm2
	movsd [ebx+ecx*8],xmm3
	sub ecx,byte 2
       js	.0
.8:	movups xmm2,[edi+ecx*8]
	movaps xmm3,xmm2
	mulpd xmm2,xmm0
	mulpd xmm3,xmm1
	movups [eax+ecx*8],xmm2
	movups [ebx+ecx*8],xmm3
	sub ecx,byte 2
       jns	.8
	pop esi
	pop edi
	pop ebx
       retn


align	4

;void fvtimes(double* or, double* oi, const double* sr, const double* si, const double* tr, const double* ti, int m, int n)
;
_fvtimes:
	push ebp
	push ebx
	push edi
	push esi
	ldmxcsr [mcsr]
	mov edi,[esp+20]		; or
	mov esi,[esp+24]		; oi
	mov ebx,[esp+32]		; si
	test esi,esi
	mov ecx,[esp+36]		; tr
	mov edx,[esp+40]		; ti
       jz near	_fvtimesor
	sub esi,edi
	test ebx,ebx
       jz near	_fvtimessr
	sub ebx,[esp+28]		; sr
	test edx,edx
       jz near	_fvtimestr
	sub edx,ecx
	test byte [esp+44],1		; complex
       jz near	.01
.11:	mov ebp,[esp+44]		; m odd
	mov eax,[esp+28]		; sr
	movsd xmm0,[ecx]
	movsd xmm1,[ecx+edx]
	sub ebp,byte 2
	movlhps xmm0,xmm0
	movlhps xmm1,xmm1
	add ecx,byte 8
.12:	movups xmm2,[eax]
	movaps xmm4,xmm2
	movups xmm3,[eax+ebx]
	movaps xmm5,xmm3
	add eax,byte 16
	mulpd xmm4,xmm0
	mulpd xmm5,xmm1
	mulpd xmm2,xmm1
	mulpd xmm3,xmm0
	subpd xmm4,xmm5
	addpd xmm2,xmm3
	sub ebp,byte 2
	movups [edi],xmm4
	movups [edi+esi],xmm2
	lea edi,[edi+16]
       jg	.12
	movsd xmm2,[eax]
	movsd xmm4,xmm2
	movsd xmm3,[eax+ebx]
	movsd xmm5,xmm3
	mulsd xmm4,xmm0
	mulsd xmm5,xmm1
	mulsd xmm2,xmm1
	mulsd xmm3,xmm0
	subsd xmm4,xmm5
	addsd xmm2,xmm3
	sub dword [esp+48],byte 1
	movsd [edi],xmm4
	movsd [edi+esi],xmm2
	lea edi,[edi+8]
       jg	.11
	pop esi
	pop edi
	pop ebx
	pop ebp
       retn
.01:	mov ebp,[esp+44]		; m even
	mov eax,[esp+28]		; sr
	movsd xmm0,[ecx]
	movsd xmm1,[ecx+edx]
	movlhps xmm0,xmm0
	movlhps xmm1,xmm1
	add ecx,byte 8
.02:	movups xmm2,[eax]
	movaps xmm4,xmm2
	movups xmm3,[eax+ebx]
	movaps xmm5,xmm3
	add eax,byte 16
	mulpd xmm4,xmm0
	mulpd xmm5,xmm1
	mulpd xmm2,xmm1
	mulpd xmm3,xmm0
	subpd xmm4,xmm5
	addpd xmm2,xmm3
	sub ebp,byte 2
	movups [edi],xmm4
	movups [edi+esi],xmm2
	lea edi,[edi+16]
       jg	.02
	sub dword [esp+48],byte 1
       jg	.01
	pop esi
	pop edi
	pop ebx
	pop ebp
       retn

align	4

_fvtimesor:				; o real
	test byte [esp+44],1
	mov ebp,[esp+48]		; n
       jz short	.01
.11:	mov ebx,[esp+44]		; m odd
	mov eax,[esp+28]		; sr
	movsd xmm0,[ecx]
	sub ebx,byte 2
	movlhps xmm0,xmm0
	add ecx,byte 8			; always: m > 1
.12:	movups xmm1,[eax]
	add eax,byte 16
	mulpd xmm1,xmm0
	sub ebx,byte 2
	movups [edi],xmm1
	lea edi,[edi+16]
       jg	.12
	mulsd xmm0,[eax]
	sub ebp,byte 1
	movsd [edi],xmm0
	lea edi,[edi+8]
       jg	.11
	pop esi
	pop edi
	pop ebx
	pop ebp
       retn
.01:	mov ebx,[esp+44]		; m even
	movsd xmm0,[ecx]
	mov eax,[esp+28]		; sr
	movlhps xmm0,xmm0
	add ecx,byte 8
.02:	movups xmm1,[eax]
	add eax,byte 16
	mulpd xmm1,xmm0
	sub ebx,byte 2
	movups [edi],xmm1
	lea edi,[edi+16]
       jg	.02
	sub ebp,byte 1
       jg	.01
	pop esi
	pop edi
	pop ebx
	pop ebp
       retn

align	4

_fvtimessr:				; s real
	sub edx,ecx
	test byte [esp+44],1
	mov ebp,[esp+48]		; n
       jz short	.01
.11:	mov ebx,[esp+44]		; m odd
	mov eax,[esp+28]		; sr
	movsd xmm0,[ecx]
	movsd xmm1,[ecx+edx]
	sub ebx,byte 2
	movlhps xmm0,xmm0
	movlhps xmm1,xmm1
	add ecx,byte 8			; always: m > 1
.12:	movups xmm2,[eax]
	movaps xmm3,xmm2
	add eax,byte 16
	mulpd xmm2,xmm0
	mulpd xmm3,xmm1
	sub ebx,byte 2
	movups [edi],xmm2
	movups [edi+esi],xmm3
	lea edi,[edi+16]
       jg	.12
	movsd xmm2,[eax]
	mulsd xmm0,xmm2
	mulsd xmm1,xmm2
	sub ebp,byte 1
	movsd [edi],xmm0
	movsd [edi+esi],xmm1
	lea edi,[edi+8]
       jg	.11
	pop esi
	pop edi
	pop ebx
	pop ebp
       retn
.01:	mov ebx,[esp+44]		; m even
	mov eax,[esp+28]		; sr
	movsd xmm0,[ecx]
	movsd xmm1,[ecx+edx]
	movlhps xmm0,xmm0
	movlhps xmm1,xmm1
	add ecx,byte 8
.02:	movups xmm2,[eax]
	movaps xmm3,xmm2
	add eax,byte 16
	mulpd xmm2,xmm0
	mulpd xmm3,xmm1
	sub ebx,byte 2
	movups [edi],xmm2
	movups [edi+esi],xmm3
	lea edi,[edi+16]
       jg	.02
	sub ebp,byte 1
       jg	.01
	pop esi
	pop edi
	pop ebx
	pop ebp
       retn

align	4

_fvtimestr:				; t real
	test byte [esp+44],1
	mov ebp,[esp+48]		; n
       jz short	.01
.11:	mov edx,[esp+44]		; m odd
	mov eax,[esp+28]		; sr
	movsd xmm0,[ecx]
	sub edx,byte 2
	movlhps xmm0,xmm0
	add ecx,byte 8			; always: m > 1
.12:	movups xmm1,[eax]
	movups xmm2,[eax+ebx]
	add eax,byte 16
	mulpd xmm1,xmm0
	mulpd xmm2,xmm0
	sub edx,byte 2
	movups [edi],xmm1
	movups [edi+esi],xmm2
	lea edi,[edi+16]
       jg	.12
	movsd xmm1,[eax]
	mulsd xmm1,xmm0
	mulsd xmm0,[eax+ebx]
	sub ebp,byte 1
	movsd [edi],xmm1
	movsd [edi+esi],xmm0
	lea edi,[edi+8]
       jg	.11
	pop esi
	pop edi
	pop ebx
	pop ebp
       retn
.01:	mov edx,[esp+44]		; m even
	movsd xmm0,[ecx]
	mov eax,[esp+28]		; sr
	movlhps xmm0,xmm0
	add ecx,byte 8
.02:	movups xmm1,[eax]
	movups xmm2,[eax+ebx]
	add eax,byte 16
	mulpd xmm1,xmm0
	mulpd xmm2,xmm0
	sub edx,byte 2
	movups [edi],xmm1
	movups [edi+esi],xmm2
	lea edi,[edi+16]
       jg	.02
	sub ebp,byte 1
       jg	.01
	pop esi
	pop edi
	pop ebx
	pop ebp
       retn
