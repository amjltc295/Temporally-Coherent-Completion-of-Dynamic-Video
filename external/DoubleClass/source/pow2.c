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
*		Base 2 power and scale floating point number		     *
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
void fpow2(double* or, double* oi, const double* sr, const double* si, int n);
void fmscale(double* or, const double* sr, const double* tr, int n);
void fsscale(double* or, const double* sr, const double* tr, int n);
void ftscale(double* or, const double* sr, const double* tr, int n);


void mexFunction(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[])
{	double *or, *oi=NULL;
	int m, n;
	if (nlhs > 1) mexErrMsgTxt("Too many output arguments.");
	switch(nrhs)
	{default:
		mexErrMsgTxt("Wrong number of input arguments.");
	 case 0:
		mexPrintf("\nBase 2 power and scale floating point number.\n\n\tMarcel Leutenegger © 12.5.2008\n\n");
		break;
	 case 1:
		O=mxCreateDoubleMatrix(0,0,mxREAL);
		mxSetDimensions(O,mxGetDimensions(S),mxGetNumberOfDimensions(S));
		n=mxGetNumberOfElements(S);
		if (n > 0)
		{	mxSetPr(O,or=mxMalloc(n*sizeof(double)));
			if (mxIsComplex(S)) mxSetPi(O,oi=mxMalloc(n*sizeof(double)));
			fpow2(or,oi,mxGetPr(S),mxGetPi(S),n);
		}
		break;
	 case 2:
		if (mxIsComplex(S) || mxIsComplex(T)) mexErrMsgTxt("Arguments must be real.");
		O=mxCreateDoubleMatrix(0,0,mxREAL);
		m=mxGetNumberOfElements(S);
		n=mxGetNumberOfElements(T);
		if (m > 0 && n > 0)
		{	if (m == 1)	// scalar,matrix
			{	mxSetDimensions(O,mxGetDimensions(T),mxGetNumberOfDimensions(T));
				mxSetPr(O,or=mxMalloc(n*sizeof(double)));
				fsscale(or,mxGetPr(S),mxGetPr(T),n);
				break;
			}
			if (n == 1)	// matrix,scalar
			{	mxSetDimensions(O,mxGetDimensions(S),mxGetNumberOfDimensions(S));
				mxSetPr(O,or=mxMalloc(m*sizeof(double)));
				ftscale(or,mxGetPr(S),mxGetPr(T),m);
				break;
			}
			if (m == n)	// matrix,matrix
			{	const int* d=mxGetDimensions(S);
				m=mxGetNumberOfDimensions(S);
				if (fdim(m,mxGetNumberOfDimensions(T),d,mxGetDimensions(T)))
				{	mxSetDimensions(O,d,m);
					mxSetPr(O,or=mxMalloc(n*sizeof(double)));
					fmscale(or,mxGetPr(S),mxGetPr(T),n);
					break;
				}
			}
			mexErrMsgTxt("Incompatible dimensions.");
		}
	}
}
