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
global	_align10mn
global	_align9mn
global	_align8mn
global	_align7mn
global	_align6mn
global	_align5mn
global	_align4mn
global	_align3mn
global	_align2mn
global	_align1mn


;void alignXmn(double* o, const double* s, int m, int n)
;
_align10mn:
	push ebx
	mov ecx,[esp+20]		; n
	mov edx,[esp+16]		; m
	mov eax,[esp+12]		; s
	mov ebx,[esp+8]			; o
	lea edx,[edx*8]
.1:	movups xmm0,[eax]
	movups xmm1,[eax+16]
	movups xmm2,[eax+32]
	movups xmm3,[eax+48]
	movups xmm4,[eax+64]
	add eax,edx
	sub ecx,byte 1
	movaps [ebx],xmm0
	movaps [ebx+16],xmm1
	movaps [ebx+32],xmm2
	movaps [ebx+48],xmm3
	movaps [ebx+64],xmm4
	lea ebx,[ebx+80]
       jg	.1
	pop ebx
       retn


align	4

_align9mn:
	push ebx
	mov ecx,[esp+20]		; n
	mov edx,[esp+16]		; m
	mov eax,[esp+12]		; s
	mov ebx,[esp+8]			; o
	lea edx,[edx*8]
.1:	movups xmm0,[eax]
	movups xmm1,[eax+16]
	movups xmm2,[eax+32]
	movups xmm3,[eax+48]
	movsd xmm4,[eax+64]
	add eax,edx
	sub ecx,byte 1
	movaps [ebx],xmm0
	movaps [ebx+16],xmm1
	movaps [ebx+32],xmm2
	movaps [ebx+48],xmm3
	movaps [ebx+64],xmm4
	lea ebx,[ebx+80]
       jg	.1
	pop ebx
       retn


align	4

_align8mn:
	push ebx
	mov ecx,[esp+20]		; n
	mov edx,[esp+16]		; m
	mov eax,[esp+12]		; s
	mov ebx,[esp+8]			; o
	lea edx,[edx*8]
.1:	movups xmm0,[eax]
	movups xmm1,[eax+16]
	movups xmm2,[eax+32]
	movups xmm3,[eax+48]
	add eax,edx
	sub ecx,byte 1
	movaps [ebx],xmm0
	movaps [ebx+16],xmm1
	movaps [ebx+32],xmm2
	movaps [ebx+48],xmm3
	lea ebx,[ebx+64]
       jg	.1
	pop ebx
       retn


align	4

_align7mn:
	push ebx
	mov ecx,[esp+20]		; n
	mov edx,[esp+16]		; m
	mov eax,[esp+12]		; s
	mov ebx,[esp+8]			; o
	lea edx,[edx*8]
.1:	movups xmm0,[eax]
	movups xmm1,[eax+16]
	movups xmm2,[eax+32]
	movsd xmm3,[eax+48]
	add eax,edx
	sub ecx,byte 1
	movaps [ebx],xmm0
	movaps [ebx+16],xmm1
	movaps [ebx+32],xmm2
	movaps [ebx+48],xmm3
	lea ebx,[ebx+64]
       jg	.1
	pop ebx
       retn


align	4

_align6mn:
	push ebx
	mov ecx,[esp+20]		; n
	mov edx,[esp+16]		; m
	mov eax,[esp+12]		; s
	mov ebx,[esp+8]			; o
	add edx,edx
	sub ecx,byte 1
       jng	.2
.1:	movups xmm0,[eax]
	movups xmm1,[eax+16]
	movups xmm2,[eax+32]
	movups xmm3,[eax+edx*4]
	movups xmm4,[eax+edx*4+16]
	movups xmm5,[eax+edx*4+32]
	lea eax,[eax+edx*8]
	sub ecx,byte 2
	movaps [ebx],xmm0
	movaps [ebx+16],xmm1
	movaps [ebx+32],xmm2
	movaps [ebx+48],xmm3
	movaps [ebx+64],xmm4
	movaps [ebx+80],xmm5
	lea ebx,[ebx+96]
       jg	.1
       jl	.0
.2:	movups xmm0,[eax]
	movups xmm1,[eax+16]
	movups xmm2,[eax+32]
	movaps [ebx],xmm0
	movaps [ebx+16],xmm1
	movaps [ebx+32],xmm2
.0:	pop ebx
       retn


align	4

_align5mn:
	push ebx
	mov ecx,[esp+20]		; n
	mov edx,[esp+16]		; m
	mov eax,[esp+12]		; s
	mov ebx,[esp+8]			; o
	add edx,edx
	sub ecx,byte 1
       jng	.2
.1:	movups xmm0,[eax]
	movups xmm1,[eax+16]
	movsd xmm2,[eax+32]
	movups xmm3,[eax+edx*4]
	movups xmm4,[eax+edx*4+16]
	movsd xmm5,[eax+edx*4+32]
	lea eax,[eax+edx*8]
	sub ecx,byte 2
	movaps [ebx],xmm0
	movaps [ebx+16],xmm1
	movaps [ebx+32],xmm2
	movaps [ebx+48],xmm3
	movaps [ebx+64],xmm4
	movaps [ebx+80],xmm5
	lea ebx,[ebx+96]
       jg	.1
       jl	.0
.2:	movups xmm0,[eax]
	movups xmm1,[eax+16]
	movsd xmm2,[eax+32]
	movaps [ebx],xmm0
	movaps [ebx+16],xmm1
	movaps [ebx+32],xmm2
.0:	pop ebx
       retn


align	4

_align4mn:
	push ebx
	mov ecx,[esp+20]		; n
	mov edx,[esp+16]		; m
	mov eax,[esp+12]		; s
	mov ebx,[esp+8]			; o
	add edx,edx
	sub ecx,byte 1
       jng	.2
.1:	movups xmm0,[eax]
	movups xmm1,[eax+16]
	movups xmm2,[eax+edx*4]
	movups xmm3,[eax+edx*4+16]
	lea eax,[eax+edx*8]
	sub ecx,byte 2
	movaps [ebx],xmm0
	movaps [ebx+16],xmm1
	movaps [ebx+32],xmm2
	movaps [ebx+48],xmm3
	lea ebx,[ebx+64]
       jg	.1
       jl	.0
.2:	movups xmm0,[eax]
	movups xmm1,[eax+16]
	movaps [ebx],xmm0
	movaps [ebx+16],xmm1
.0:	pop ebx
       retn


align	4

_align3mn:
	push ebx
	mov ecx,[esp+20]		; n
	mov edx,[esp+16]		; m
	mov eax,[esp+12]		; s
	mov ebx,[esp+8]			; o
	add edx,edx
	sub ecx,byte 1
       jng	.2
.1:	movups xmm0,[eax]
	movsd xmm1,[eax+16]
	movups xmm2,[eax+edx*4]
	movsd xmm3,[eax+edx*4+16]
	lea eax,[eax+edx*8]
	sub ecx,byte 2
	movaps [ebx],xmm0
	movaps [ebx+16],xmm1
	movaps [ebx+32],xmm2
	movaps [ebx+48],xmm3
	lea ebx,[ebx+64]
       jg	.1
       jl	.0
.2:	movups xmm0,[eax]
	movsd xmm1,[eax+16]
	movaps [ebx],xmm0
	movaps [ebx+16],xmm1
.0:	pop ebx
       retn


align	4

_align2mn:
	push ebx
	mov ecx,[esp+20]		; n
	mov edx,[esp+16]		; m
	mov eax,[esp+12]		; s
	mov ebx,[esp+8]			; o
	add edx,edx
	sub ecx,byte 3
       jng	.2
.1:	movups xmm0,[eax]
	movups xmm1,[eax+edx*4]
	lea eax,[eax+edx*8]
	add ebx,byte 64
	movups xmm2,[eax]
	movups xmm3,[eax+edx*4]
	lea eax,[eax+edx*8]
	sub ecx,byte 4
	movaps [ebx-64],xmm0
	movaps [ebx-48],xmm1
	movaps [ebx-32],xmm2
	movaps [ebx-16],xmm3
       jg	.1
.2:    jz	.4
	cmp ecx,byte -2
       jl	.0
       jg	.3
	movups xmm0,[eax]		; 1 left
	movaps [ebx],xmm0
	pop ebx
       retn
.3:	movups xmm0,[eax]		; 2 left
	movups xmm1,[eax+edx*4]
	movaps [ebx],xmm0
	movaps [ebx+16],xmm1
	pop ebx
       retn
.4:	movups xmm0,[eax]		; 3 left
	movups xmm1,[eax+edx*4]
	movups xmm2,[eax+edx*8]
	movaps [ebx],xmm0
	movaps [ebx+16],xmm1
	movaps [ebx+32],xmm2
.0:	pop ebx
       retn


align	4

_align1mn:
	push ebx
	mov ecx,[esp+20]		; n
	mov edx,[esp+16]		; m
	mov eax,[esp+12]		; s
	mov ebx,[esp+8]			; o
	add edx,edx
	sub ecx,byte 3
       jng	.2
.1:	movsd xmm0,[eax]
	movsd xmm1,[eax+edx*4]
	lea eax,[eax+edx*8]
	add ebx,byte 64
	movsd xmm2,[eax]
	movsd xmm3,[eax+edx*4]
	lea eax,[eax+edx*8]
	sub ecx,byte 4
	movaps [ebx-64],xmm0
	movaps [ebx-48],xmm1
	movaps [ebx-32],xmm2
	movaps [ebx-16],xmm3
       jg	.1
.2:    jz	.4
	cmp ecx,byte -2
       jl	.0
       jg	.3
	movsd xmm0,[eax]		; 1 left
	movaps [ebx],xmm0
	pop ebx
       retn
.3:	movsd xmm0,[eax]		; 2 left
	movsd xmm1,[eax+edx*4]
	movaps [ebx],xmm0
	movaps [ebx+16],xmm1
	pop ebx
       retn
.4:	movsd xmm0,[eax]		; 3 left
	movsd xmm1,[eax+edx*4]
	movsd xmm2,[eax+edx*8]
	movaps [ebx],xmm0
	movaps [ebx+16],xmm1
	movaps [ebx+32],xmm2
.0:	pop ebx
       retn
