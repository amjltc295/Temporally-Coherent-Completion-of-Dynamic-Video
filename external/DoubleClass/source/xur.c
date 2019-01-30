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
*				  Exclusive or				     *
*									     *
*									     *
*			Marcel Leutenegger © 12.5.2008			     *
*									     *
\****************************************************************************/

#include "mex.h"
#define	O	plhs[0]
#define	S	prhs[0]
#define	T	prhs[1]

bool fdim(int m, int n, const int* d, const int* e);
void fmxur(char* or, const double* sr, const double* si, const double* tr, const double* ti, int n);
void ftxur(char* or, const double* sr, const double* si, const double* tr, const double* ti, int n);


void mexFunction(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[])
{	char* or;
	int m, n;
	if (nlhs > 1) mexErrMsgTxt("Too many output arguments.");
	switch(nrhs)
	{default:
		mexErrMsgTxt("Wrong number of input arguments.");
	 case 0:
		mexPrintf("\nExclusive or.\n\n\tMarcel Leutenegger © 12.5.2008\n\n");
		break;
	 case 2:
		O=mxCreateNumericMatrix(0,0,mxUINT8_CLASS,mxREAL);
		m=mxGetNumberOfElements(S);
		n=mxGetNumberOfElements(T);
		mxSetLogical(O);
		if (m > 0 && n > 0)
		{	if (m == 1)	// scalar,matrix
			{	mxSetDimensions(O,mxGetDimensions(T),mxGetNumberOfDimensions(T));
				mxSetData(O,or=mxMalloc(n));
				ftxur(or,mxGetPr(T),mxGetPi(T),mxGetPr(S),mxGetPi(S),n);
				break;
			}
			if (n == 1)	// matrix,scalar
			{	mxSetDimensions(O,mxGetDimensions(S),mxGetNumberOfDimensions(S));
				mxSetData(O,or=mxMalloc(m));
				ftxur(or,mxGetPr(S),mxGetPi(S),mxGetPr(T),mxGetPi(T),m);
				break;
			}
			if (m == n)	// matrix,matrix
			{	const int* d=mxGetDimensions(S);
				m=mxGetNumberOfDimensions(S);
				if (fdim(m,mxGetNumberOfDimensions(T),d,mxGetDimensions(T)))
				{	mxSetDimensions(O,d,m);
					mxSetData(O,or=mxMalloc(n));
					fmxur(or,mxGetPr(S),mxGetPi(S),mxGetPr(T),mxGetPi(T),n);
					break;
				}
			}
			mexErrMsgTxt("Incompatible dimensions.");
		}
	}
}
