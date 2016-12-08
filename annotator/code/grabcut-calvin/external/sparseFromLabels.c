/*
 * =============================================================
 * sparseLogicalFromLabels.c
 * Create a sparse assignment matrix from a label vector: each row is a cluster, each column is a data point.
 * There is at most one nonzero value per column, given by the input vector.
 * mex -largeArrayDims sparseLogicalFromLabels.c
 * =============================================================
 */


#include "mex.h"

void mexFunction(
        int nlhs,       mxArray *plhs[],
        int nrhs, const mxArray *prhs[]
        )
{
    
    
  /* Declare variables. */
  int j,k,m,p;
  double *sr, *labels, *idx;
  mwIndex *irs, *jcs;
  mwSize n,c;

  /* Check for proper number of input and output arguments. */    
  if (nrhs < 2 || nrhs > 3) {
    mexErrMsgTxt("Two or three input argument required.");
  } 

  /* Check data type of input argument. */
  if (!mxIsDouble(prhs[0]) || mxIsSparse(prhs[0])) {
    mexErrMsgTxt("The first argument must be a full double vector.");
  }
  
  if (nrhs==3) {
      if (!mxIsDouble(prhs[2]) || mxIsSparse(prhs[2])) {
          mexErrMsgTxt("The third argument must be a full double vector.");
      }
      if (mxGetNumberOfElements(prhs[0]) != mxGetNumberOfElements(prhs[2])) {
          mexErrMsgTxt("The third argument must be the same size as the first.");
      };
  }
  
  
  if (!mxIsScalar(prhs[1])) {
    mexErrMsgTxt("The second argument must be a scalar.");
  }
  
  labels = mxGetPr(prhs[0]); /* pointer to labels */
  n  = mxGetNumberOfElements(prhs[0]); /* number of data points */
  c  = mxGetScalar(prhs[1]); /* largest label */
  
  plhs[0] = mxCreateSparse(c,n,n,mxREAL);
  sr  = mxGetPr(plhs[0]);
  irs = mxGetIr(plhs[0]);
  jcs = mxGetJc(plhs[0]);
  
  if (nrhs!=3) {
      for (j=0;j<n;j++) {
          irs[j] = (int) labels[j]-1;
          sr[j] = (double) 1;
          jcs[j] = j;
      }
  } else {
      double *val = mxGetPr(prhs[2]); /* pointer to values */
      for (j=0;j<n;j++) {
          irs[j] = (int) labels[j]-1;
          sr[j] = val[j];
          jcs[j] = j;
      }
  }
  jcs[n] = n;
  
}
