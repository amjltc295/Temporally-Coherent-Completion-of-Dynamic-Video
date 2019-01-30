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
global	_fangle


;void fangle(double* or, const double* sr, const double* si, int n)
;
_fangle:
	push ebx
	fninit
	mov ecx,[esp+20]	; n
	mov ebx,[esp+16]	; si
	sub ecx,byte 1
	mov eax,[esp+12]	; sr
	test ebx,ebx
	mov edx,[esp+8]		; or
       jz	.3
.1:	fld qword [ebx+ecx*8]
	fucomi st0
       jp	.2
	fld qword [eax+ecx*8]
	fucomi st0
       jp	.2
	fpatan
.2:	fstp qword [edx+ecx*8]
	sub ecx,byte 1
	ffree st0
       jns	.1
	pop ebx
       retn
.3:	fldpi			; real
	fldz
.4:	fld qword [eax+ecx*8]
	fucomi st1
       jp	.5
	fcmovb st2
	fcmovnb st1
.5:	fstp qword [edx+ecx*8]
	sub ecx,byte 1
       jns	.4
	ffree st1
	pop ebx
	ffree st0
       retn
