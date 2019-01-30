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
global	_init10kn			; initialize block
global	_init8kn
global	_init6kn
global	_init4kn
global	_init2kn

global	_madd10kn			; add with block
global	_madd8kn
global	_madd6kn
global	_madd4kn
global	_madd2kn

global	_msub10kn			; subtract from block
global	_msub8kn
global	_msub6kn
global	_msub4kn
global	_msub2kn


;void initXkn(double* o, const double* s, const double* t, int k, int dk, int dn)
;
_init10kn:
	push ebx
	push edi
	push esi
	mov eax,[esp+36]		; dn
	mov edx,[esp+28]		; k
	mov esi,[esp+24]		; t
	mov edi,[esp+20]		; s
	mov ebx,[esp+16]		; o
	sub edx,[esp+32]		; dk
.1:	movsd xmm0,[esi]
	movaps xmm3,[edi]
	movlhps xmm0,xmm0
	movaps xmm4,[edi+16]
	mulpd xmm3,xmm0
	movaps xmm5,[edi+32]
	mulpd xmm4,xmm0
	movaps xmm6,[edi+48]
	mulpd xmm5,xmm0
	movaps xmm7,[edi+64]
	mulpd xmm6,xmm0
	mov ecx,[esp+32]		; dk
	add edi,byte 80
	movsd xmm2,[esi+8]
	add esi,byte 8
	sub ecx,byte 2
	mulpd xmm7,xmm0
       jz	.3
.2:	movaps xmm0,[edi]
	movlhps xmm2,xmm2
	movaps xmm1,[edi+16]
	mulpd xmm0,xmm2
	add esi,byte 8
	sub ecx,byte 1
	addpd xmm3,xmm0
	movaps xmm0,[edi+32]
	mulpd xmm1,xmm2
	addpd xmm4,xmm1
	movaps xmm1,[edi+48]
	mulpd xmm0,xmm2
	addpd xmm5,xmm0
	movaps xmm0,[edi+64]
	mulpd xmm1,xmm2
	lea edi,[edi+80]
	addpd xmm6,xmm1
	mulpd xmm0,xmm2
	movsd xmm2,[esi]
	addpd xmm7,xmm0
       jg	.2
.3:	movaps xmm0,[edi]
	movlhps xmm2,xmm2
	movaps xmm1,[edi+16]
	mulpd xmm0,xmm2
	add ebx,byte 80
	lea esi,[esi+edx*8+8]
	addpd xmm3,xmm0
	movaps xmm0,[edi+32]
	mulpd xmm1,xmm2
	addpd xmm4,xmm1
	movaps xmm1,[edi+48]
	mulpd xmm0,xmm2
	mulpd xmm1,xmm2
	addpd xmm5,xmm0
	mulpd xmm2,[edi+64]
	addpd xmm6,xmm1
	mov edi,[esp+20]		; s
	sub eax,byte 1
	addpd xmm7,xmm2
	movaps [ebx-80],xmm3
	movaps [ebx-64],xmm4
	movaps [ebx-48],xmm5
	movaps [ebx-32],xmm6
	movaps [ebx-16],xmm7
       jg	.1
	pop esi
	pop edi
	pop ebx
       retn


align	4

_init8kn:
	push ebx
	push edi
	push esi
	mov eax,[esp+36]		; dn
	mov edx,[esp+28]		; k
	mov esi,[esp+24]		; t
	mov edi,[esp+20]		; s
	mov ebx,[esp+16]		; o
	sub edx,[esp+32]		; dk
.1:	movsd xmm7,[esi]
	movaps xmm4,[edi]
	movlhps xmm7,xmm7
	movaps xmm5,[edi+16]
	mulpd xmm4,xmm7
	movaps xmm6,[edi+32]
	mulpd xmm5,xmm7
	add esi,byte 8
	mov ecx,[esp+32]		; dk
	mulpd xmm6,xmm7
	mulpd xmm7,[edi+48]
	add edi,byte 64
	sub ecx,byte 2
	movsd xmm3,[esi]
       jz	.3
.2:	movaps xmm0,[edi]
	movaps xmm1,[edi+16]
	movlhps xmm3,xmm3
	movaps xmm2,[edi+32]
	add esi,byte 8
	sub ecx,byte 1
	mulpd xmm0,xmm3
	mulpd xmm1,xmm3
	addpd xmm4,xmm0
	mulpd xmm2,xmm3
	addpd xmm5,xmm1
	mulpd xmm3,[edi+48]
	lea edi,[edi+64]
	addpd xmm6,xmm2
	addpd xmm7,xmm3
	movsd xmm3,[esi]
       jg	.2
.3:	movaps xmm0,[edi]
	movaps xmm1,[edi+16]
	movlhps xmm3,xmm3
	movaps xmm2,[edi+32]
	add ebx,byte 64
	lea esi,[esi+edx*8+8]
	mulpd xmm0,xmm3
	mulpd xmm1,xmm3
	addpd xmm4,xmm0
	mulpd xmm2,xmm3
	addpd xmm5,xmm1
	mulpd xmm3,[edi+48]
	sub eax,byte 1
	mov edi,[esp+20]		; s
	addpd xmm6,xmm2
	addpd xmm7,xmm3
	movaps [ebx-64],xmm4
	movaps [ebx-48],xmm5
	movaps [ebx-32],xmm6
	movaps [ebx-16],xmm7
       jg	.1
	pop esi
	pop edi
	pop ebx
       retn


align	4

_init6kn:
	push ebx
	push edi
	push esi
	mov eax,[esp+36]		; dn
	mov edx,[esp+28]		; k
	mov esi,[esp+24]		; t
	mov edi,[esp+20]		; s
	mov ebx,[esp+16]		; o
	sub edx,[esp+32]		; dk
.1:	movsd xmm6,[esi]
	movaps xmm4,[edi]
	movlhps xmm6,xmm6
	movaps xmm5,[edi+16]
	mulpd xmm4,xmm6
	movsd xmm2,[esi+8]
	add esi,byte 8
	mov ecx,[esp+32]		; dk
	mulpd xmm5,xmm6
	mulpd xmm6,[edi+32]
	add edi,byte 48
	sub ecx,byte 2
       jz	.3
.2:	movaps xmm0,[edi]
	movaps xmm1,[edi+16]
	movlhps xmm2,xmm2
	add esi,byte 8
	sub ecx,byte 1
	mulpd xmm0,xmm2
	mulpd xmm1,xmm2
	addpd xmm4,xmm0
	mulpd xmm2,[edi+32]
	lea edi,[edi+48]
	addpd xmm5,xmm1
	addpd xmm6,xmm2
	movsd xmm2,[esi]
       jg	.2
.3:	movaps xmm0,[edi]
	movaps xmm1,[edi+16]
	movlhps xmm2,xmm2
	add ebx,byte 48
	lea esi,[esi+edx*8+8]
	mulpd xmm0,xmm2
	mulpd xmm1,xmm2
	addpd xmm4,xmm0
	mulpd xmm2,[edi+32]
	addpd xmm5,xmm1
	mov edi,[esp+20]		; s
	sub eax,byte 1
	addpd xmm6,xmm2
	movaps [ebx-48],xmm4
	movaps [ebx-32],xmm5
	movaps [ebx-16],xmm6
       jg	.1
	pop esi
	pop edi
	pop ebx
       retn


align	4

_init4kn:
	push ebx
	push edi
	push esi
	mov eax,[esp+36]		; dn
	mov edx,[esp+28]		; k
	mov esi,[esp+24]		; t
	mov edi,[esp+20]		; s
	mov ebx,[esp+16]		; o
	sub edx,[esp+32]		; dk
.1:	movsd xmm5,[esi]
	movaps xmm4,[edi]
	movlhps xmm5,xmm5
	movsd xmm1,[esi+8]
	add esi,byte 8
	mov ecx,[esp+32]		; dk
	mulpd xmm4,xmm5
	mulpd xmm5,[edi+16]
	add edi,byte 32
	sub ecx,byte 2
       jz	.3
.2:	movaps xmm0,[edi]
	movlhps xmm1,xmm1
	add esi,byte 8
	sub ecx,byte 1
	mulpd xmm0,xmm1
	mulpd xmm1,[edi+16]
	lea edi,[edi+32]
	addpd xmm4,xmm0
	addpd xmm5,xmm1
	movsd xmm1,[esi]
       jg	.2
.3:	movaps xmm0,[edi]
	movlhps xmm1,xmm1
	add ebx,byte 32
	lea esi,[esi+edx*8+8]
	mulpd xmm0,xmm1
	mulpd xmm1,[edi+16]
	sub eax,byte 1
	mov edi,[esp+20]		; s
	addpd xmm4,xmm0
	addpd xmm5,xmm1
	movaps [ebx-32],xmm4
	movaps [ebx-16],xmm5
       jg	.1
	pop esi
	pop edi
	pop ebx
       retn


align	4

_init2kn:
	push ebx
	push edi
	push esi
	mov eax,[esp+36]		; dn
	mov edx,[esp+28]		; k
	mov esi,[esp+24]		; t
	mov edi,[esp+20]		; s
	mov ebx,[esp+16]		; o
	sub edx,[esp+32]		; dk
.1:	movsd xmm4,[esi]
	movsd xmm0,[esi+8]
	movlhps xmm4,xmm4
	add esi,byte 8
	mov ecx,[esp+32]		; dk
	mulpd xmm4,[edi]
	add edi,byte 16
	sub ecx,byte 2
       jz	.3
.2:	movlhps xmm0,xmm0
	add esi,byte 8
	sub ecx,byte 1
	mulpd xmm0,[edi]
	lea edi,[edi+16]
	addpd xmm4,xmm0
	movsd xmm0,[esi]
       jg	.2
.3:	movlhps xmm0,xmm0
	lea esi,[esi+edx*8+8]
	add ebx,byte 16
	mulpd xmm0,[edi]
	sub eax,byte 1
	mov edi,[esp+20]		; s
	addpd xmm4,xmm0
	movaps [ebx-16],xmm4
       jg	.1
	pop esi
	pop edi
	pop ebx
       retn


align	4

_madd10kn:
	push ebx
	push edi
	push esi
	mov eax,[esp+36]		; dn
	mov edx,[esp+28]		; k
	mov esi,[esp+24]		; t
	mov edi,[esp+20]		; s
	mov ebx,[esp+16]		; o
	sub edx,[esp+32]		; dk
.1:	movsd xmm0,[esi]
	movaps xmm3,[edi]
	movlhps xmm0,xmm0
	movaps xmm4,[edi+16]
	mulpd xmm3,xmm0
	movaps xmm5,[edi+32]
	mulpd xmm4,xmm0
	addpd xmm3,[ebx]
	movaps xmm6,[edi+48]
	mulpd xmm5,xmm0
	addpd xmm4,[ebx+16]
	movaps xmm7,[edi+64]
	mulpd xmm6,xmm0
	addpd xmm5,[ebx+32]
	mov ecx,[esp+32]		; dk
	add edi,byte 80
	movsd xmm2,[esi+8]
	mulpd xmm7,xmm0
	addpd xmm6,[ebx+48]
	add esi,byte 8
	sub ecx,byte 2
	addpd xmm7,[ebx+64]
       jz	.3
.2:	movaps xmm0,[edi]
	movlhps xmm2,xmm2
	movaps xmm1,[edi+16]
	mulpd xmm0,xmm2
	add esi,byte 8
	sub ecx,byte 1
	addpd xmm3,xmm0
	movaps xmm0,[edi+32]
	mulpd xmm1,xmm2
	addpd xmm4,xmm1
	movaps xmm1,[edi+48]
	mulpd xmm0,xmm2
	addpd xmm5,xmm0
	movaps xmm0,[edi+64]
	mulpd xmm1,xmm2
	lea edi,[edi+80]
	addpd xmm6,xmm1
	mulpd xmm0,xmm2
	movsd xmm2,[esi]
	addpd xmm7,xmm0
       jg	.2
.3:	movaps xmm0,[edi]
	movlhps xmm2,xmm2
	movaps xmm1,[edi+16]
	mulpd xmm0,xmm2
	add ebx,byte 80
	lea esi,[esi+edx*8+8]
	addpd xmm3,xmm0
	movaps xmm0,[edi+32]
	mulpd xmm1,xmm2
	addpd xmm4,xmm1
	movaps xmm1,[edi+48]
	mulpd xmm0,xmm2
	mulpd xmm1,xmm2
	addpd xmm5,xmm0
	mulpd xmm2,[edi+64]
	addpd xmm6,xmm1
	mov edi,[esp+20]		; s
	sub eax,byte 1
	addpd xmm7,xmm2
	movaps [ebx-80],xmm3
	movaps [ebx-64],xmm4
	movaps [ebx-48],xmm5
	movaps [ebx-32],xmm6
	movaps [ebx-16],xmm7
       jg	.1
	pop esi
	pop edi
	pop ebx
       retn


align	4

;void maddXkn(double* o, const double* s, const double* t, int k, int dk, int dn)
;
_madd8kn:
	push ebx
	push edi
	push esi
	mov eax,[esp+36]		; dn
	mov edx,[esp+28]		; k
	mov esi,[esp+24]		; t
	mov edi,[esp+20]		; s
	mov ebx,[esp+16]		; o
	sub edx,[esp+32]		; dk
.1:	movsd xmm7,[esi]
	movaps xmm4,[edi]
	movlhps xmm7,xmm7
	movaps xmm5,[edi+16]
	mulpd xmm4,xmm7
	movaps xmm6,[edi+32]
	mulpd xmm5,xmm7
	addpd xmm4,[ebx]
	add esi,byte 8
	mov ecx,[esp+32]		; dk
	mulpd xmm6,xmm7
	addpd xmm5,[ebx+16]
	mulpd xmm7,[edi+48]
	add edi,byte 64
	sub ecx,byte 2
	addpd xmm6,[ebx+32]
	movsd xmm3,[esi]
	addpd xmm7,[ebx+48]
       jz	.3
.2:	movaps xmm0,[edi]
	movaps xmm1,[edi+16]
	movlhps xmm3,xmm3
	movaps xmm2,[edi+32]
	add esi,byte 8
	sub ecx,byte 1
	mulpd xmm0,xmm3
	mulpd xmm1,xmm3
	addpd xmm4,xmm0
	mulpd xmm2,xmm3
	addpd xmm5,xmm1
	mulpd xmm3,[edi+48]
	lea edi,[edi+64]
	addpd xmm6,xmm2
	addpd xmm7,xmm3
	movsd xmm3,[esi]
       jg	.2
.3:	movaps xmm0,[edi]
	movaps xmm1,[edi+16]
	movlhps xmm3,xmm3
	movaps xmm2,[edi+32]
	add ebx,byte 64
	lea esi,[esi+edx*8+8]
	mulpd xmm0,xmm3
	mulpd xmm1,xmm3
	addpd xmm4,xmm0
	mulpd xmm2,xmm3
	addpd xmm5,xmm1
	mulpd xmm3,[edi+48]
	sub eax,byte 1
	mov edi,[esp+20]		; s
	addpd xmm6,xmm2
	addpd xmm7,xmm3
	movaps [ebx-64],xmm4
	movaps [ebx-48],xmm5
	movaps [ebx-32],xmm6
	movaps [ebx-16],xmm7
       jg	.1
	pop esi
	pop edi
	pop ebx
       retn


align	4

_madd6kn:
	push ebx
	push edi
	push esi
	mov eax,[esp+36]		; dn
	mov edx,[esp+28]		; k
	mov esi,[esp+24]		; t
	mov edi,[esp+20]		; s
	mov ebx,[esp+16]		; o
	sub edx,[esp+32]		; dk
.1:	movsd xmm6,[esi]
	movaps xmm4,[edi]
	movlhps xmm6,xmm6
	movaps xmm5,[edi+16]
	mulpd xmm4,xmm6
	movsd xmm2,[esi+8]
	mulpd xmm5,xmm6
	addpd xmm4,[ebx]
	add esi,byte 8
	mov ecx,[esp+32]		; dk
	addpd xmm5,[ebx+16]
	mulpd xmm6,[edi+32]
	add edi,byte 48
	sub ecx,byte 2
	addpd xmm6,[ebx+32]
       jz	.3
.2:	movaps xmm0,[edi]
	movaps xmm1,[edi+16]
	movlhps xmm2,xmm2
	add esi,byte 8
	sub ecx,byte 1
	mulpd xmm0,xmm2
	mulpd xmm1,xmm2
	addpd xmm4,xmm0
	mulpd xmm2,[edi+32]
	lea edi,[edi+48]
	addpd xmm5,xmm1
	addpd xmm6,xmm2
	movsd xmm2,[esi]
       jg	.2
.3:	movaps xmm0,[edi]
	movaps xmm1,[edi+16]
	movlhps xmm2,xmm2
	add ebx,byte 48
	lea esi,[esi+edx*8+8]
	mulpd xmm0,xmm2
	mulpd xmm1,xmm2
	addpd xmm4,xmm0
	mulpd xmm2,[edi+32]
	addpd xmm5,xmm1
	mov edi,[esp+20]		; s
	sub eax,byte 1
	addpd xmm6,xmm2
	movaps [ebx-48],xmm4
	movaps [ebx-32],xmm5
	movaps [ebx-16],xmm6
       jg	.1
	pop esi
	pop edi
	pop ebx
       retn


align	4

_madd4kn:
	push ebx
	push edi
	push esi
	mov eax,[esp+36]		; dn
	mov edx,[esp+28]		; k
	mov esi,[esp+24]		; t
	mov edi,[esp+20]		; s
	mov ebx,[esp+16]		; o
	sub edx,[esp+32]		; dk
.1:	movsd xmm5,[esi]
	movaps xmm4,[edi]
	movlhps xmm5,xmm5
	movsd xmm1,[esi+8]
	mulpd xmm4,xmm5
	mulpd xmm5,[edi+16]
	addpd xmm4,[ebx]
	add esi,byte 8
	mov ecx,[esp+32]		; dk
	addpd xmm5,[ebx+16]
	add edi,byte 32
	sub ecx,byte 2
       jz	.3
.2:	movaps xmm0,[edi]
	movlhps xmm1,xmm1
	add esi,byte 8
	sub ecx,byte 1
	mulpd xmm0,xmm1
	mulpd xmm1,[edi+16]
	lea edi,[edi+32]
	addpd xmm4,xmm0
	addpd xmm5,xmm1
	movsd xmm1,[esi]
       jg	.2
.3:	movaps xmm0,[edi]
	movlhps xmm1,xmm1
	add ebx,byte 32
	lea esi,[esi+edx*8+8]
	mulpd xmm0,xmm1
	mulpd xmm1,[edi+16]
	sub eax,byte 1
	mov edi,[esp+20]		; s
	addpd xmm4,xmm0
	addpd xmm5,xmm1
	movaps [ebx-32],xmm4
	movaps [ebx-16],xmm5
       jg	.1
	pop esi
	pop edi
	pop ebx
       retn


align	4

_madd2kn:
	push ebx
	push edi
	push esi
	mov eax,[esp+36]		; dn
	mov edx,[esp+28]		; k
	mov esi,[esp+24]		; t
	mov edi,[esp+20]		; s
	mov ebx,[esp+16]		; o
	sub edx,[esp+32]		; dk
.1:	movsd xmm4,[esi]
	movsd xmm0,[esi+8]
	movlhps xmm4,xmm4
	add esi,byte 8
	mov ecx,[esp+32]		; dk
	mulpd xmm4,[edi]
	add edi,byte 16
	sub ecx,byte 2
	addpd xmm4,[ebx]
       jz	.3
.2:	movlhps xmm0,xmm0
	add esi,byte 8
	sub ecx,byte 1
	mulpd xmm0,[edi]
	lea edi,[edi+16]
	addpd xmm4,xmm0
	movsd xmm0,[esi]
       jg	.2
.3:	movlhps xmm0,xmm0
	lea esi,[esi+edx*8+8]
	add ebx,byte 16
	mulpd xmm0,[edi]
	sub eax,byte 1
	mov edi,[esp+20]		; s
	addpd xmm4,xmm0
	movaps [ebx-16],xmm4
       jg	.1
	pop esi
	pop edi
	pop ebx
       retn


align	4

_msub10kn:
	push ebx
	push edi
	push esi
	mov eax,[esp+36]		; dn
	mov edx,[esp+28]		; k
	mov esi,[esp+24]		; t
	mov edi,[esp+20]		; s
	mov ebx,[esp+16]		; o
	sub edx,[esp+32]		; dk
.1:	movsd xmm2,[esi]
	movaps xmm3,[ebx]
	movaps xmm4,[ebx+16]
	movaps xmm5,[ebx+32]
	movaps xmm6,[ebx+48]
	movaps xmm7,[ebx+64]
	mov ecx,[esp+32]		; dk
	sub ecx,byte 1
.2:	movaps xmm0,[edi]
	movlhps xmm2,xmm2
	movaps xmm1,[edi+16]
	mulpd xmm0,xmm2
	add esi,byte 8
	sub ecx,byte 1
	subpd xmm3,xmm0
	movaps xmm0,[edi+32]
	mulpd xmm1,xmm2
	subpd xmm4,xmm1
	movaps xmm1,[edi+48]
	mulpd xmm0,xmm2
	subpd xmm5,xmm0
	movaps xmm0,[edi+64]
	mulpd xmm1,xmm2
	lea edi,[edi+80]
	subpd xmm6,xmm1
	mulpd xmm0,xmm2
	movsd xmm2,[esi]
	subpd xmm7,xmm0
       jg	.2
	movaps xmm0,[edi]
	movlhps xmm2,xmm2
	movaps xmm1,[edi+16]
	mulpd xmm0,xmm2
	add ebx,byte 80
	lea esi,[esi+edx*8+8]
	subpd xmm3,xmm0
	movaps xmm0,[edi+32]
	mulpd xmm1,xmm2
	subpd xmm4,xmm1
	movaps xmm1,[edi+48]
	mulpd xmm0,xmm2
	mulpd xmm1,xmm2
	subpd xmm5,xmm0
	mulpd xmm2,[edi+64]
	subpd xmm6,xmm1
	mov edi,[esp+20]		; s
	sub eax,byte 1
	subpd xmm7,xmm2
	movaps [ebx-80],xmm3
	movaps [ebx-64],xmm4
	movaps [ebx-48],xmm5
	movaps [ebx-32],xmm6
	movaps [ebx-16],xmm7
       jg	.1
	pop esi
	pop edi
	pop ebx
       retn


align	4

;void msubXkn(double* o, const double* s, const double* t, int k, int dk, int dn)
;
_msub8kn:
	push ebx
	push edi
	push esi
	mov eax,[esp+36]		; dn
	mov edx,[esp+28]		; k
	mov esi,[esp+24]		; t
	mov edi,[esp+20]		; s
	mov ebx,[esp+16]		; o
	sub edx,[esp+32]		; dk
.1:	movsd xmm3,[esi]
	movaps xmm0,[edi]
	movaps xmm1,[edi+16]
	movlhps xmm3,xmm3
	movaps xmm2,[edi+32]
	add esi,byte 8
	mov ecx,[esp+32]		; dk
	mulpd xmm0,xmm3
	movaps xmm4,[ebx]
	mulpd xmm1,xmm3
	movaps xmm5,[ebx+16]
	subpd xmm4,xmm0
	movaps xmm6,[ebx+32]
	mulpd xmm2,xmm3
	movaps xmm7,[ebx+48]
	subpd xmm5,xmm1
	mulpd xmm3,[edi+48]
	add edi,byte 64
	sub ecx,byte 2
	subpd xmm6,xmm2
	subpd xmm7,xmm3
	movsd xmm3,[esi]
       jz	.3
.2:	movaps xmm0,[edi]
	movaps xmm1,[edi+16]
	movlhps xmm3,xmm3
	movaps xmm2,[edi+32]
	add esi,byte 8
	sub ecx,byte 1
	mulpd xmm0,xmm3
	mulpd xmm1,xmm3
	subpd xmm4,xmm0
	mulpd xmm2,xmm3
	subpd xmm5,xmm1
	mulpd xmm3,[edi+48]
	lea edi,[edi+64]
	subpd xmm6,xmm2
	subpd xmm7,xmm3
	movsd xmm3,[esi]
       jg	.2
.3:	movaps xmm0,[edi]
	movaps xmm1,[edi+16]
	movlhps xmm3,xmm3
	movaps xmm2,[edi+32]
	add ebx,byte 64
	lea esi,[esi+edx*8+8]
	mulpd xmm0,xmm3
	mulpd xmm1,xmm3
	subpd xmm4,xmm0
	mulpd xmm2,xmm3
	subpd xmm5,xmm1
	mulpd xmm3,[edi+48]
	sub eax,byte 1
	mov edi,[esp+20]		; s
	subpd xmm6,xmm2
	subpd xmm7,xmm3
	movaps [ebx-64],xmm4
	movaps [ebx-48],xmm5
	movaps [ebx-32],xmm6
	movaps [ebx-16],xmm7
       jg	.1
	pop esi
	pop edi
	pop ebx
       retn


align	4

_msub6kn:
	push ebx
	push edi
	push esi
	mov eax,[esp+36]		; dn
	mov edx,[esp+28]		; k
	mov esi,[esp+24]		; t
	mov edi,[esp+20]		; s
	mov ebx,[esp+16]		; o
	sub edx,[esp+32]		; dk
.1:	movsd xmm3,[esi]
	movaps xmm0,[edi]
	movaps xmm1,[edi+16]
	movlhps xmm3,xmm3
	mov ecx,[esp+32]		; dk
	add esi,byte 8
	movaps xmm4,[ebx]
	mulpd xmm0,xmm3
	movaps xmm5,[ebx+16]
	mulpd xmm1,xmm3
	movaps xmm6,[ebx+32]
	subpd xmm4,xmm0
	mulpd xmm3,[edi+32]
	add edi,byte 48
	sub ecx,byte 2
	subpd xmm5,xmm1
	movsd xmm2,[esi]
	subpd xmm6,xmm3
       jz	.3
.2:	movaps xmm0,[edi]
	movaps xmm1,[edi+16]
	movlhps xmm2,xmm2
	add esi,byte 8
	sub ecx,byte 1
	mulpd xmm0,xmm2
	mulpd xmm1,xmm2
	subpd xmm4,xmm0
	mulpd xmm2,[edi+32]
	lea edi,[edi+48]
	subpd xmm5,xmm1
	subpd xmm6,xmm2
	movsd xmm2,[esi]
       jg	.2
.3:	movaps xmm0,[edi]
	movaps xmm1,[edi+16]
	movlhps xmm2,xmm2
	add ebx,byte 48
	lea esi,[esi+edx*8+8]
	mulpd xmm0,xmm2
	mulpd xmm1,xmm2
	subpd xmm4,xmm0
	mulpd xmm2,[edi+32]
	subpd xmm5,xmm1
	mov edi,[esp+20]		; s
	sub eax,byte 1
	subpd xmm6,xmm2
	movaps [ebx-48],xmm4
	movaps [ebx-32],xmm5
	movaps [ebx-16],xmm6
       jg	.1
	pop esi
	pop edi
	pop ebx
       retn


align	4

_msub4kn:
	push ebx
	push edi
	push esi
	mov eax,[esp+36]		; dn
	mov edx,[esp+28]		; k
	mov esi,[esp+24]		; t
	mov edi,[esp+20]		; s
	mov ebx,[esp+16]		; o
	sub edx,[esp+32]		; dk
.1:	movsd xmm3,[esi]
	movaps xmm0,[edi]
	movaps xmm4,[ebx]
	movlhps xmm3,xmm3
	movsd xmm1,[esi+8]
	movaps xmm5,[ebx+16]
	add esi,byte 8
	mov ecx,[esp+32]		; dk
	mulpd xmm0,xmm3
	mulpd xmm3,[edi+16]
	subpd xmm4,xmm0
	add edi,byte 32
	sub ecx,byte 2
	subpd xmm5,xmm3
       jz	.3
.2:	movaps xmm0,[edi]
	movlhps xmm1,xmm1
	add esi,byte 8
	sub ecx,byte 1
	mulpd xmm0,xmm1
	mulpd xmm1,[edi+16]
	lea edi,[edi+32]
	subpd xmm4,xmm0
	subpd xmm5,xmm1
	movsd xmm1,[esi]
       jg	.2
.3:	movaps xmm0,[edi]
	movlhps xmm1,xmm1
	add ebx,byte 32
	lea esi,[esi+edx*8+8]
	mulpd xmm0,xmm1
	mulpd xmm1,[edi+16]
	sub eax,byte 1
	mov edi,[esp+20]		; s
	subpd xmm4,xmm0
	subpd xmm5,xmm1
	movaps [ebx-32],xmm4
	movaps [ebx-16],xmm5
       jg	.1
	pop esi
	pop edi
	pop ebx
       retn


align	4

_msub2kn:
	push ebx
	push edi
	push esi
	mov eax,[esp+36]		; dn
	mov edx,[esp+28]		; k
	mov esi,[esp+24]		; t
	mov edi,[esp+20]		; s
	mov ebx,[esp+16]		; o
	sub edx,[esp+32]		; dk
.1:	movsd xmm1,[esi]
	movsd xmm0,[esi+8]
	movlhps xmm1,xmm1
	movaps xmm4,[ebx]
	add esi,byte 8
	mov ecx,[esp+32]		; dk
	mulpd xmm1,[edi]
	add edi,byte 16
	sub ecx,byte 2
	subpd xmm4,xmm1
       jz	.3
.2:	movlhps xmm0,xmm0
	add esi,byte 8
	sub ecx,byte 1
	mulpd xmm0,[edi]
	lea edi,[edi+16]
	subpd xmm4,xmm0
	movsd xmm0,[esi]
       jg	.2
.3:	movlhps xmm0,xmm0
	lea esi,[esi+edx*8+8]
	add ebx,byte 16
	mulpd xmm0,[edi]
	sub eax,byte 1
	mov edi,[esp+20]		; s
	subpd xmm4,xmm0
	movaps [ebx-16],xmm4
       jg	.1
	pop esi
	pop edi
	pop ebx
       retn
