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
global	_fmxur
global	_ftxur


;void fxxur(char* or, const double* sr, const double* si, const double* tr, const double* ti, int n)
;
_fmxur:
	push ebp
	push ebx
	push edi
	push esi
	mov ecx,[esp+40]	; n
	mov esi,[esp+36]	; ti
	sub ecx,byte 1
	mov edi,[esp+32]	; tr
	mov eax,esi
	mov edx,[esp+28]	; si
	mov ebx,[esp+24]	; sr
	or eax,edx
	mov ebp,[esp+20]	; or
	fldz
       jz	.2		; real
	test esi,esi
       jz	.3		; t real
	test edx,edx
       jz	.4		; s real
.1:	fld qword [ebx+ecx*8]
	fld qword [edx+ecx*8]
	fucomip st1
	setp ah
	setnz al
	or ah,al
	fucomip st1
	fld qword [edi+ecx*8]
	fld qword [esi+ecx*8]
	setnz al
	or ah,al
	fucomip st1
	bswap eax
	setp ah
	setnz al
	or ah,al
	fucomip st1
	setnz al
	or ah,al
	shr eax,8
	xor al,ah
	mov [ecx+ebp],al
	sub ecx,byte 1
       jns	.1
	ffree st0
	pop esi
	pop edi
	pop ebx
	pop ebp
       retn
.2:	fld qword [ebx+ecx*8]	; real
	fucomip st1
	fld qword [edi+ecx*8]
	setp ah
	setnz al
	or al,ah
	fucomip st1
	setp dh
	setnz dl
	or dl,dh
	xor al,dl
	mov [ecx+ebp],al
	sub ecx,byte 1
       jns	.2
	ffree st0
	pop esi
	pop edi
	pop ebx
	pop ebp
       retn
.3:	xchg ebx,edi		; t real
	xchg edx,esi
.4:	fld qword [ebx+ecx*8]	; s real
	fucomip st1
	fld qword [edi+ecx*8]
	fld qword [esi+ecx*8]
	setp ah
	setnz al
	or ah,al
	fucomip st1
	setp dh
	setnz dl
	or dh,dl
	fucomip st1
	setnz dl
	or dl,dh
	xor al,dl
	mov [ecx+ebp],al
	sub ecx,byte 1
       jns	.4
	ffree st0
	pop esi
	pop edi
	pop ebx
	pop ebp
       retn


align	4

_ftxur:
	push ebx
	push edi
	push esi
	mov ecx,[esp+36]	; n
	mov edx,[esp+32]	; ti
	sub ecx,byte 1
	mov ebx,[esp+28]	; tr
	fldz
	mov esi,[esp+24]	; si
	fld qword [ebx]
	mov edi,[esp+20]	; sr
	fucomip st1
	mov eax,[esp+16]	; or
	setp bh
	setnz bl
	or bl,bh
	test edx,edx
       jz	.1		; t real
	fld qword [edx]
	fucomip st1
	setp dh
	setnz dl
	or dl,dh
	or bl,dl
.1:	test esi,esi
       jz	.3		; s real
.2:	fld qword [edi+ecx*8]
	fld qword [esi+ecx*8]
	fucomip st1
	setp dh
	setnz dl
	or dh,dl
	fucomip st1
	setnz dl
	or dl,dh
	xor dl,bl
	mov [eax+ecx],dl
	sub ecx,byte 1
       jns	.2
	ffree st0
	pop esi
	pop edi
	pop ebx
       retn
.3:	fld qword [edi+ecx*8]	; s real
	fucomip st1
	setp dh
	setnz dl
	or dl,dh
	xor dl,bl
	mov [eax+ecx],dl
	sub ecx,byte 1
       jns	.3
	ffree st0
	pop esi
	pop edi
	pop ebx
       retn
