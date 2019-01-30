/*
  Optimized double class functions for MATLAB on x86 computers.
  Copyright © Marcel Leutenegger, 2003-2008, École Polytechnique Fédérale de Lausanne (EPFL),
  Laboratoire d'Optique Biomédicale (LOB), BM - Station 17, 1015 Lausanne, Switzerland.

      This library is free software; you can redistribute it and/or modify it under
      the terms of the GNU Lesser General Public License as published by the Free
      Software Foundation; version 2.1 of the License.

      This library is distributed in the hope that it will be useful, but WITHOUT ANY
      WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
      PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.

      You should have received a copy of the GNU Lesser General Public License along
      with this library; if not, write to the Free Software Foundation, Inc.,
      51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
*/

/****************************************************************************\
*									     *
*		Read the timestamp counter of Pentium processors	     *
*									     *
*									     *
*			Marcel Leutenegger © 12.5.2008			     *
*									     *
\****************************************************************************/

#include "mex.h"
#define	T	plhs[0]

void ftimer(double* t);


/*
	t=timer
	-------

	Read the timestamp counter of Pentium processors.

		Marcel Leutenegger © 12.5.2008

	Output:
	 t	Elapsed processor clocks since last call
*/
void mexFunction(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[])
{	if (nlhs)
	{	T=mxCreateDoubleMatrix(1,1,mxREAL);
		ftimer(mxGetPr(T));
	}
	else	ftimer(NULL);
}
