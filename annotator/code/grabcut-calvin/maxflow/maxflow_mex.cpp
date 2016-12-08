//------------------------------------------------------------------------
// MAXFLOWMEX	A wrapper library for maximum flow calculation.
//	Input:
//	A - an NxN sparse matrix of real entries.
//	T - as Nx2 sparse matrix of real entries.
//  Output:
//  flow - maximum flow value
//  labels - a vector of size Nx1 containing the label of each node 
//           respectively
//
//  Note that it is not guaranteed that A will be checked for correct
//  construction (e.g. self loops, etc). That is, garbage in - garbage out.
// 
//	(c) 2008 Michael Rubinstein, WDI R&D and IDC
//	$Revision: 140 $
//	$Date: 2008-09-15 15:35:01 -0700 (Mon, 15 Sep 2008) $
//------------------------------------------------------------------------

#include "mex.h"
#include "maxflow-v3.0/graph.h"


void mexFunction(int			nlhs, 		/* number of expected outputs */
				 mxArray		*plhs[],	/* mxArray output pointer array */
				 int			nrhs, 		/* number of inputs */
				 const mxArray	*prhs[]		/* mxArray input pointer array */)
{
	// input checks
	if (nrhs != 2 || !mxIsSparse(prhs[0]) || !mxIsSparse(prhs[1]))
	{
		mexErrMsgTxt ("USAGE: [flow,labels] = maxflowmex(A,T)");
	}
	const mxArray *A = prhs[0];
	const mxArray *T = prhs[1];
	if (mxIsComplex(A) || mxIsComplex(T))
	{
		mexErrMsgTxt ("Complex entries are not supported!");
	}
	// fetch its dimensions
	// actually, we must have m=n
	mwSize m = mxGetM(A);
	mwSize n = mxGetN(A);
	mwSize nzmax = mxGetNzmax(A);
	if (m != n)
	{
		mexErrMsgTxt ("Matrix A should be square!");
	}
	if (n != mxGetM(T) || mxGetN(T) != 2)
	{
		mexErrMsgTxt ("T should be of size Nx2");
	}

	// sparse matrices have a different storage convention from that of full matrices in MATLAB. 
	// The parameters pr and pi are still arrays of double-precision numbers, but these arrays 
	// contain only nonzero data elements. There are three additional parameters: nzmax, ir, and jc.
	// nzmax - is an integer that contains the length of ir, pr, and, if it exists, pi. It is the maximum 
	// possible number of nonzero elements in the sparse matrix.
	// ir - points to an integer array of length nzmax containing the row indices of the corresponding 
	// elements in pr and pi.
	// jc - points to an integer array of length n+1, where n is the number of columns in the sparse matrix. 
	// The jc array contains column index information. If the jth column of the sparse matrix has any nonzero
	// elements, jc[j] is the index in ir and pr (and pi if it exists) of the first nonzero element in the jth
	// column, and jc[j+1] - 1 is the index of the last nonzero element in that column. For the jth column of 
	// the sparse matrix, jc[j] is the total number of nonzero elements in all preceding columns. The last 
	// element of the jc array, jc[n], is equal to nnz, the number of nonzero elements in the entire sparse matrix. 
	// If nnz is less than nzmax, more nonzero entries can be inserted into the array without allocating additional 
	// storage.

	double *pr = mxGetPr(A);
	mwIndex *ir = mxGetIr(A);
	mwIndex *jc = mxGetJc(A);

	// create graph
	typedef Graph<float,float,float> GraphType;
	// estimations for number of nodes and edges - we know these exactly!
	GraphType *g = new GraphType(/*estimated # of nodes*/ n, /*estimated # of edges*/ jc[n]); 
	
	// add the nodes
	// NOTE: their indices are 0-based
    g->add_node(n);

	// traverse the adjacency matrix and add n-links
	unsigned int i, j, k;
	float v;
	for (j = 0; j < n; j++)
	{
		// this is a simple check whether there are non zero
		// entries in the j'th column
		if (jc[j] == jc[j+1])
		{
			continue; // nothing in this column
		}
		for (k = jc[j]; k <= jc[j+1]-1; k++)
		{
			i = ir[k];
			v = (float)pr[k];
			//mexPrintf("non zero entry: (%d,%d) = %.2f\n", i+1, j+1, v);
			g->add_edge(i, j, v, 0.0f);
		}
	}

	// traverse the terminal matrix and add t-links
	pr = mxGetPr(T);
	ir = mxGetIr(T);
	jc = mxGetJc(T);
	for (j = 0; j <= 1; j++)
	{
		if (jc[j] == jc[j+1])
		{
			continue;
		}
		for (k = jc[j]; k <= jc[j+1]-1; k++)
		{
			i = ir[k];
			v = (float)pr[k];

			if (j == 0) // source weight
			{
				g->add_tweights(i, v, 0.0f);
			}
			else if (j == 1) // sink weight
			{
				g->add_tweights(i, 0.0f, v);
			}
		}
	}

	plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
	double* flow = mxGetPr(plhs[0]);
	*flow = g->maxflow();

	// figure out segmentation
	plhs[1] = mxCreateNumericMatrix(n, 1, mxINT32_CLASS, mxREAL);
	int* labels = (int*)mxGetData(plhs[1]);
	for (i = 0; i < n; i++)
	{
		labels[i] = g->what_segment(i);
	}

	// cleanup
	delete g;
}

