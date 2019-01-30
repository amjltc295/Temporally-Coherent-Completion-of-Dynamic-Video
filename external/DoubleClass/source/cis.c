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
*			        Sine and cosine				     *
*									     *
*									     *
*			Marcel Leutenegger © 12.5.2008			     *
*									     *
\****************************************************************************/

#include "mex.h"
#define	O	plhs[0]
#define	P	plhs[1]
#define	S	prhs[0]
#define	T	prhs[1]

bool fdim(int m, int n, const int* d, const int* e);
void fcis(double* or, double* oi, const double* sr, int n);
void fmcis(double* or, double* oi, const double* sr, const double* tr, int n);
void fscis(double* or, double* oi, const double* sr, const double* tr, int n);
void ftcis(double* or, double* oi, const double* sr, const double* tr, int n);


void mexFunction(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[])
{	double *or, *oi;
	const int* d;
	int m, n;
	if (nlhs > 2) mexErrMsgTxt("Too many output arguments.");
	switch(nrhs)
	{default:
		mexErrMsgTxt("Wrong number of input arguments.");
	 case 0:
		mexPrintf("\nSine and cosine.\n\n\tMarcel Leutenegger © 12.5.2008\n\n");
		break;
	 case 1:
		if (mxIsComplex(S)) mexErrMsgTxt("Argument must be real.");
		O=mxCreateDoubleMatrix(0,0,mxREAL);
		mxSetDimensions(O,d=mxGetDimensions(S),m=mxGetNumberOfDimensions(S));
		if (nlhs > 1)
		{	P=mxCreateDoubleMatrix(0,0,mxREAL);
			mxSetDimensions(P,d,m);
		}
		n=mxGetNumberOfElements(S);
		if (n > 0)
		{	mxSetPr(O,or=mxMalloc(n*sizeof(double)));
			oi=mxMalloc(n*sizeof(double));
			if (nlhs > 1)
				mxSetPr(P,oi);
			else	mxSetPi(O,oi);
			fcis(or,oi,mxGetPr(S),n);
		}
		break;
	 case 2:
		if (mxIsComplex(S) || mxIsComplex(T)) mexErrMsgTxt("Arguments must be real.");
		O=mxCreateDoubleMatrix(0,0,mxREAL);
		if (nlhs > 1) P=mxCreateDoubleMatrix(0,0,mxREAL);
		m=mxGetNumberOfElements(S);
		n=mxGetNumberOfElements(T);
		if (m > 0 && n > 0)
		{	if (m == 1)	// scalar,matrix
			{	mxSetDimensions(O,d=mxGetDimensions(T),m=mxGetNumberOfDimensions(T));
				mxSetPr(O,or=mxMalloc(n*sizeof(double)));
				oi=mxMalloc(n*sizeof(double));
				if (nlhs > 1)
				{	mxSetDimensions(P,d,m);
					mxSetPr(P,oi);
				}
				else	mxSetPi(O,oi);
				fscis(or,oi,mxGetPr(S),mxGetPr(T),n);
				break;
			}
			if (n == 1)	// matrix,scalar
			{	mxSetDimensions(O,d=mxGetDimensions(S),n=mxGetNumberOfDimensions(S));
				mxSetPr(O,or=mxMalloc(m*sizeof(double)));
				oi=mxMalloc(m*sizeof(double));
				if (nlhs > 1)
				{	mxSetDimensions(P,d,n);
					mxSetPr(P,oi);
				}
				else	mxSetPi(O,oi);
				ftcis(or,oi,mxGetPr(S),mxGetPr(T),m);
				break;
			}
			if (m == n)	// matrix,matrix
			{	d=mxGetDimensions(S);
				m=mxGetNumberOfDimensions(S);
				if (fdim(m,mxGetNumberOfDimensions(T),d,mxGetDimensions(T)))
				{	mxSetDimensions(O,d,m);
					mxSetPr(O,or=mxMalloc(n*sizeof(double)));
					oi=mxMalloc(n*sizeof(double));
					if (nlhs > 1)
					{	mxSetDimensions(P,d,m);
						mxSetPr(P,oi);
					}
					else	mxSetPi(O,oi);
					fmcis(or,oi,mxGetPr(S),mxGetPr(T),n);
					break;
				}
			}
			mexErrMsgTxt("Incompatible dimensions.");
		}
	}
}
