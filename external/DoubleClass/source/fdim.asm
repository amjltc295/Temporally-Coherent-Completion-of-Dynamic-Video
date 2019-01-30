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
global	_fdim


;bool fdim(int m, int n, const int* d, const int* e)
;
_fdim:
	mov ecx,[esp+4]
	cmp ecx,[esp+8]
       jnz	.0
	push edi
	push esi
	pushfd
	cld
	mov edi,[esp+24]
	mov esi,[esp+28]
	repz cmpsd
       jnz	.1
	popfd
	pop esi
	pop edi
	mov eax,1
       retn
.1:	popfd
	pop esi
	pop edi
.0:	xor eax,eax
       retn
