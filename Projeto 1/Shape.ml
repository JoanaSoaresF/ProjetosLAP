(* Shape module body *)

(* 
Aluno 1: Goncalo Lourenco n55780
Aluno 2:  Joana Faria n55754

Comment:

*)

(*
01234567890123456789012345678901234567890123456789012345678901234567890123456789
   80 columns
*)


(* COMPILATION - How to build this module
         ocamlc -c Shape.mli Shape.ml
*)



(* TYPES *)

type point = float*float;;

type shape = Rect of point*point
           | Circle of point*float
           | Union of shape*shape
           | Intersection of shape*shape
           | Subtraction of shape*shape
;;


(* EXAMPLES *)

let rect1 = Rect ((0.0, 0.0), (5.0, 2.0));;
let rect2 = Rect ((2.0, 2.0), (7.0, 7.0));;
let shape1 = Union (rect1, rect2);;


(* FUNCTION hasRect *)

let rec hasRect s =
    match s with
          Rect (p,q) -> true
        | Circle (p,f) -> false
        | Union (l,r) -> hasRect l || hasRect r
        | Intersection (l,r) -> hasRect l || hasRect r
        | Subtraction (l,r) -> hasRect l || hasRect r
;;


(* FUNCTION countBasic *)

let rec countBasic s =
    match s with
          Rect (p,q) -> failwith "countBasic: Rect"
        | Circle (p,f) -> failwith "countBasic: Circle"
        | Union (l,r) -> failwith "countBasic: Union"
        | Intersection (l,r) -> failwith "countBasic: Intersection"
        | Subtraction (l,r) -> failwith "countBasic: Subtraction"
;;


(* FUNCTION belongs *)

let belongs p s =
    true
;;


(* FUNCTION density *)

let density p s =
    0
;;


(* FUNCTION which *)

let which p s =
    [s]
;;


(* FUNCTION minBound *)

let minBound s =
    rect1
;;


(* FUNCTION grid *)

let grid m n a b =
    shape1
;;


(* FUNCTION countBasicRepetitions *)

let countBasicRepetitions s =
    0
;;


(* FUNCTION svg *)

let svg s =
    ""
;;


(* FUNCTION partition *)

let partition s =
    [s]
;;

