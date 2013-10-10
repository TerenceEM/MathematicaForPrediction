(*
    Implementation of the Non-Negative Matrix Factorization algorithm in Mathematica
    Copyright (C) 2013  Anton Antonov

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

	Written by Anton Antonov, 
	antononcube@gmail.com, 
	7320 Colbury Ave, 
	Windermere, Florida, USA.
*)

(*
    Mathematica is (C) Copyright 1988-2013 Wolfram Research, Inc.

    Protected by copyright law and international treaties.

    Unauthorized reproduction or distribution subject to severe civil
    and criminal penalties.

    Mathematica is a registered trademark of Wolfram Research, Inc.
*)

(* Version 1.0 *)
(* This package contains definitions for the application of Non-Negative Matrix Factorization (NNMF). *)
(* *)

BeginPackage["NonNegativeMatrixFactorization`"]

GDCLS::usage = "GDCLS[V_?MatrixQ,k_Integer,tol_?NumberQ] returns the pair of matrices {W,H} such that V = W H and the number of the columns of W and the number of rows of H are k. The method used is Gradient Descent with Constrained Least Squares."

GDCLSGlobal::usage = "GDCLSGlobal[V_?MatrixQ,tol_?NumberQ] continues the GDCLS iterations over the matrices W and H in the execution context and returns {W,H} as a result."

NormalizeMatrixProduct::usage = "NormalizeMatrixProduct[W_?MatrixQ,H_?MatrixQ] returns a pair of matrices {W1,H1} such that W1 H1 = W H and the norms of the columns of W1 are 1."

RightNormalizeMatrixProduct::usage = "RightNormalizeMatrixProduct[W_?MatrixQ,H_?MatrixQ] returns a pair of matrices {W1,H1} such that W1 H1 = W H and the norms of the rows of H1 are 1."

BasisVectorInterpretation::usage = "BasisVectorInterpretation[vec_?VectorQ,n_Integer,interpretationItems_List] takes the n largest coordinates of vec, finds the corresponding elements in interpretationItems, and returns a list of coordinate-item pairs."

Begin["`Private`"]

Clear[GDCLS]
Options[GDCLS] = {"MaxSteps" -> 200, "NonNegative" -> True, "Epsilon" -> 10^-9., "RegularizationParameter" -> 0.01, PrecisionGoal -> Automatic, "PrintProfilingInfo" -> False};
GDCLS[V_?MatrixQ, k_?IntegerQ, opts___] :=
  Block[{t, fls, A, W, H, T, m, n, b, diffNorm, normV, nSteps = 0,
    nonnegQ = "NonNegative" /. {opts} /. Options[GDCLS],
    maxSteps = "MaxSteps" /. {opts} /. Options[GDCLS],
    eps = "Epsilon" /. {opts} /. Options[GDCLS],
    lbd = "RegularizationParameter" /. {opts} /. Options[GDCLS],
    pgoal = PrecisionGoal /. {opts} /. Options[GDCLS],
    PRINT = If[TrueQ["PrintProfilingInfo" /. {opts}] /. Options[GDCLS], Print, None]},
   {m, n} = Dimensions[V];
   W = RandomReal[{0, 1}, {m, k}];
   H = ConstantArray[0, {k, n}];
   normV = Norm[V, "Frobenius"]; diffNorm = 10 normV;
   While[nSteps < maxSteps && TrueQ[! NumberQ[pgoal] || NumberQ[pgoal] && (normV > 0) && diffNorm/normV > 10^(-pgoal)],
    nSteps++;
    t =
     Timing[
      A = Transpose[W].W + lbd*IdentityMatrix[k];
      T = Transpose[W];
      fls = LinearSolve[A];
      H = Table[(b = T.V[[All, i]]; fls[b]), {i, 1, n}];
      H = SparseArray[Transpose[H]];
      If[nonnegQ,
       H = Clip[H, {0, Max[H]}]
       ];
      W = W*(V.Transpose[H])/(W.(H.Transpose[H]) + eps);
      ];
    If[NumberQ[pgoal],
      diffNorm = Norm[V - W.H, "Frobenius"];
      If[nSteps < 100 || Mod[nSteps, 100] == 0, PRINT[nSteps, " ", t, " relative error=", diffNorm/normV]],
      If[nSteps < 100 || Mod[nSteps, 100] == 0, PRINT[nSteps, " ", t]]
     ];
    ];
   {W, H}
   ];

Clear[GDCLSGlobal]
GDCLSGlobal[V_?MatrixQ, opts___] :=
  Block[{t, fls, A, W, H, T, m, n, b, k, diffNorm, normV, nSteps = 0,
     nonnegQ = "NonNegative" /. {opts} /. Options[GDCLS],
     maxSteps = "MaxSteps" /. {opts} /. Options[GDCLS],
     eps = "Epsilon" /. {opts} /. Options[GDCLS],
     lbd = "RegularizationParameter" /. {opts} /. Options[GDCLS],
     pgoal = PrecisionGoal /. {opts} /. Options[GDCLS],
     PRINT = If[TrueQ["PrintProfilingInfo" /. {opts}] /. Options[GDCLS], Print, None]},
    {m, n} = Dimensions[V];
    k = Dimensions[H][[1]];
    normV = Norm[V, "Frobenius"]; diffNorm = 10 normV;
    While[nSteps < maxSteps && TrueQ[! NumberQ[pgoal] || NumberQ[pgoal] && (normV > 0) && diffNorm/normV > 10^(-pgoal)],
     nSteps++;
     t =
      Timing[
       A = Transpose[W].W + lbd*IdentityMatrix[k];
       T = Transpose[W];
       fls = LinearSolve[A];
       H = Table[(b = T.V[[All, i]]; fls[b]), {i, 1, n}];
       H = SparseArray[Transpose[H]];
       If[nonnegQ,
        H = Clip[H, {0, Max[H]}]
        ];
       W = W*(V.Transpose[H])/(W.(H.Transpose[H]) + eps);
       ];
     If[NumberQ[pgoal],
      diffNorm = Norm[V - W.H, "Frobenius"];
      If[nSteps < 100 || Mod[nSteps, 100] == 0, PRINT[nSteps, " ", t, " relative error=", diffNorm/normV]],
      If[nSteps < 100 || Mod[nSteps, 100] == 0, PRINT[nSteps, " ", t]]
      ]
     ];
    {W, H}
    ] /; MatrixQ[W] && MatrixQ[H] && Length[W[[1]]] == Length[H];

(* ::Subsection:: *)
(*Normalize matrices*)

Clear[NormalizeMatrixProduct]
NormalizeMatrixProduct[W_?MatrixQ,H_?MatrixQ]:=
  Block[{d,S,SI},
    d=Table[Norm[W[[All,i]]],{i,Length[W[[1]]]}];
    S=DiagonalMatrix[d];
    SI=DiagonalMatrix[Map[If[#!=0,1/#,0]&,d]];
    {W.(SI),S.H}
  ];

Clear[RightNormalizeMatrixProduct]
RightNormalizeMatrixProduct[W_?MatrixQ,H_?MatrixQ]:=
  Block[{d,S,SI},
    d=Table[Norm[H[[i]]],{i,Length[H]}];
    S=DiagonalMatrix[d];
    SI=DiagonalMatrix[1/d];
    {W.S,SI.H}
  ];

Clear[BasisVectorInterpretation]
BasisVectorInterpretation[vec_,n_Integer,terms_]:=
  Block[{t},
    t=Reverse@Ordering[vec,-n];
    Transpose[{vec[[t]],terms[[t]]}]
  ];


End[]

EndPackage[]