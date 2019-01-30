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
global	_store10mn
global	_store9mn
global	_store8mn
global	_store7mn
global	_store6mn
global	_store5mn
global	_store4mn
global	_store3mn
global	_store2mn
global	_store1mn


;void storeXmn(double* o, const double* s, int m, int n)
;
_store10mn:
	push ebx
	mov ecx,[esp+20]		; n
	mov edx,[esp+16]		; m
	mov eax,[esp+12]		; s
	mov ebx,[esp+8]			; o
.1:	movaps xmm0,[eax]
	movaps xmm1,[eax+16]
	movaps xmm2,[eax+32]
	movaps xmm3,[eax+48]
	movaps xmm4,[eax+64]
	add eax,byte 80
	sub ecx,byte 1
	movups [ebx],xmm0
	movups [ebx+16],xmm1
	movups [ebx+32],xmm2
	movups [ebx+48],xmm3
	movups [ebx+64],xmm4
	lea ebx,[ebx+edx*8]
       jg	.1
	pop ebx
       retn


align	4

_store9mn:
	push ebx
	mov ecx,[esp+20]		; n
	mov edx,[esp+16]		; m
	mov eax,[esp+12]		; s
	mov ebx,[esp+8]			; o
.1:	movaps xmm0,[eax]
	movaps xmm1,[eax+16]
	movaps xmm2,[eax+32]
	movaps xmm3,[eax+48]
	movaps xmm4,[eax+64]
	add eax,byte 80
	sub ecx,byte 1
	movups [ebx],xmm0
	movups [ebx+16],xmm1
	movups [ebx+32],xmm2
	movups [ebx+48],xmm3
	movlps [ebx+64],xmm4
	lea ebx,[ebx+edx*8]
       jg	.1
	pop ebx
       retn


align	4

_store8mn:
	push ebx
	mov ecx,[esp+20]		; n
	mov edx,[esp+16]		; m
	mov eax,[esp+12]		; s
	mov ebx,[esp+8]			; o
	add edx,edx
	sub ecx,byte 1
       jng	.2
.1:	movaps xmm0,[eax]
	movaps xmm1,[eax+16]
	movaps xmm2,[eax+32]
	movaps xmm3,[eax+48]
	movaps xmm4,[eax+64]
	movaps xmm5,[eax+80]
	movaps xmm6,[eax+96]
	movaps xmm7,[eax+112]
	sub eax,byte -128
	sub ecx,byte 2
	movups [ebx],xmm0
	movups [ebx+16],xmm1
	movups [ebx+32],xmm2
	movups [ebx+48],xmm3
	movups [ebx+edx*4],xmm4
	movups [ebx+edx*4+16],xmm5
	movups [ebx+edx*4+32],xmm6
	movups [ebx+edx*4+48],xmm7
	lea ebx,[ebx+edx*8]
       jg	.1
       jl	.0
.2:	movaps xmm0,[eax]
	movaps xmm1,[eax+16]
	movaps xmm2,[eax+32]
	movaps xmm3,[eax+48]
	movups [ebx],xmm0
	movups [ebx+16],xmm1
	movups [ebx+32],xmm2
	movups [ebx+48],xmm3
.0:	pop ebx
       retn


align	4

_store7mn:
	push ebx
	mov ecx,[esp+20]		; n
	mov edx,[esp+16]		; m
	mov eax,[esp+12]		; s
	mov ebx,[esp+8]			; o
	add edx,edx
	sub ecx,byte 1
       jng	.2
.1:	movaps xmm0,[eax]
	movaps xmm1,[eax+16]
	movaps xmm2,[eax+32]
	movaps xmm3,[eax+48]
	movaps xmm4,[eax+64]
	movaps xmm5,[eax+80]
	movaps xmm6,[eax+96]
	movaps xmm7,[eax+112]
	sub eax,byte -128
	sub ecx,byte 2
	movups [ebx],xmm0
	movups [ebx+16],xmm1
	movups [ebx+32],xmm2
	movlps [ebx+48],xmm3
	movups [ebx+edx*4],xmm4
	movups [ebx+edx*4+16],xmm5
	movups [ebx+edx*4+32],xmm6
	movlps [ebx+edx*4+48],xmm7
	lea ebx,[ebx+edx*8]
       jg	.1
       jl	.0
.2:	movaps xmm0,[eax]
	movaps xmm1,[eax+16]
	movaps xmm2,[eax+32]
	movaps xmm3,[eax+48]
	movups [ebx],xmm0
	movups [ebx+16],xmm1
	movups [ebx+32],xmm2
	movlps [ebx+48],xmm3
.0:	pop ebx
       retn


align	4

_store6mn:
	push ebx
	mov ecx,[esp+20]		; n
	mov edx,[esp+16]		; m
	mov eax,[esp+12]		; s
	mov ebx,[esp+8]			; o
	add edx,edx
	sub ecx,byte 1
       jng	.2
.1:	movaps xmm0,[eax]
	movaps xmm1,[eax+16]
	movaps xmm2,[eax+32]
	movaps xmm3,[eax+48]
	movaps xmm4,[eax+64]
	movaps xmm5,[eax+80]
	add eax,byte 96
	sub ecx,byte 2
	movups [ebx],xmm0
	movups [ebx+16],xmm1
	movups [ebx+32],xmm2
	movups [ebx+edx*4],xmm3
	movups [ebx+edx*4+16],xmm4
	movups [ebx+edx*4+32],xmm5
	lea ebx,[ebx+edx*8]
       jg	.1
       jl	.0
.2:	movaps xmm0,[eax]
	movaps xmm1,[eax+16]
	movaps xmm2,[eax+32]
	movups [ebx],xmm0
	movups [ebx+16],xmm1
	movups [ebx+32],xmm2
.0:	pop ebx
       retn


align	4

_store5mn:
	push ebx
	mov ecx,[esp+20]		; n
	mov edx,[esp+16]		; m
	mov eax,[esp+12]		; s
	mov ebx,[esp+8]			; o
	add edx,edx
	sub ecx,byte 1
       jng	.2
.1:	movaps xmm0,[eax]
	movaps xmm1,[eax+16]
	movaps xmm2,[eax+32]
	movaps xmm3,[eax+48]
	movaps xmm4,[eax+64]
	movaps xmm5,[eax+80]
	add eax,byte 96
	sub ecx,byte 2
	movups [ebx],xmm0
	movups [ebx+16],xmm1
	movlps [ebx+32],xmm2
	movups [ebx+edx*4],xmm3
	movups [ebx+edx*4+16],xmm4
	movlps [ebx+edx*4+32],xmm5
	lea ebx,[ebx+edx*8]
       jg	.1
       jl	.0
.2:	movaps xmm0,[eax]
	movaps xmm1,[eax+16]
	movaps xmm2,[eax+32]
	movups [ebx],xmm0
	movups [ebx+16],xmm1
	movlps [ebx+32],xmm2
.0:	pop ebx
       retn


align	4

_store4mn:
	push ebx
	mov ecx,[esp+20]		; n
	mov edx,[esp+16]		; m
	mov eax,[esp+12]		; s
	mov ebx,[esp+8]			; o
	add edx,edx
	sub ecx,byte 1
       jng	.2
.1:	movaps xmm0,[eax]
	movaps xmm1,[eax+16]
	movaps xmm2,[eax+32]
	movaps xmm3,[eax+48]
	add eax,byte 64
	sub ecx,byte 2
	movups [ebx],xmm0
	movups [ebx+16],xmm1
	movups [ebx+edx*4],xmm2
	movups [ebx+edx*4+16],xmm3
	lea ebx,[ebx+edx*8]
       jg	.1
       jl	.0
.2:	movaps xmm0,[eax]
	movaps xmm1,[eax+16]
	movups [ebx],xmm0
	movups [ebx+16],xmm1
.0:	pop ebx
       retn


align	4

_store3mn:
	push ebx
	mov ecx,[esp+20]		; n
	mov edx,[esp+16]		; m
	mov eax,[esp+12]		; s
	mov ebx,[esp+8]			; o
	add edx,edx
	sub ecx,byte 1
       jng	.2
.1:	movaps xmm0,[eax]
	movaps xmm1,[eax+16]
	movaps xmm2,[eax+32]
	movaps xmm3,[eax+48]
	add eax,byte 64
	sub ecx,byte 2
	movups [ebx],xmm0
	movlps [ebx+16],xmm1
	movups [ebx+edx*4],xmm2
	movlps [ebx+edx*4+16],xmm3
	lea ebx,[ebx+edx*8]
       jg	.1
       jl	.0
.2:	movaps xmm0,[eax]
	movaps xmm1,[eax+16]
	movups [ebx],xmm0
	movlps [ebx+16],xmm1
.0:	pop ebx
       retn


align	4

_store2mn:
	push ebx
	mov ecx,[esp+20]		; n
	mov edx,[esp+16]		; m
	mov eax,[esp+12]		; s
	mov ebx,[esp+8]			; o
	add edx,edx
	sub ecx,byte 1
       jng	.2
.1:	movaps xmm0,[eax]
	movaps xmm1,[eax+16]
	add eax,byte 32
	sub ecx,byte 2
	movups [ebx],xmm0
	movups [ebx+edx*4],xmm1
	lea ebx,[ebx+edx*8]
       jg	.1
       jl	.0
.2:	movaps xmm0,[eax]
	movups [ebx],xmm0
.0:	pop ebx
       retn


align	4

_store1mn:
	push ebx
	mov ecx,[esp+20]		; n
	mov edx,[esp+16]		; m
	mov eax,[esp+12]		; s
	mov ebx,[esp+8]			; o
	add edx,edx
	sub ecx,byte 1
       jng	.2
.1:	movaps xmm0,[eax]
	movaps xmm1,[eax+16]
	add eax,byte 32
	sub ecx,byte 2
	movlps [ebx],xmm0
	movlps [ebx+edx*4],xmm1
	lea ebx,[ebx+edx*8]
       jg	.1
       jl	.0
.2:	movaps xmm0,[eax]
	movlps [ebx],xmm0
.0:	pop ebx
       retn
