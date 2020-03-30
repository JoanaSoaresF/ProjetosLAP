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

let rec countBasic s = (*e os failwith??*)
  match s with
    Rect (p,q) -> 1
  | Circle (p,f) -> 1 
  | Union (l,r) 
  | Intersection (l,r) 
  | Subtraction (l,r) -> countBasic l + countBasic r
;;


(* FUNCTION belongs *)
let belongsRect p t b =
  match p with
    (px, py) -> match t with
      (tx, ty) -> if px>=tx && py>=ty 
      then match b with
          (bx, by) -> px<=bx && py<=by
      else
        false
;;

let belongsCircle p c f =
  match p with
    (px, py) -> match c with
      (cx, cy) -> Pervasives.sqrt(((px-.cx)*.(px-.cx)) +. ((py-.cy)*.(py-.cy)))<=f
;;
let rec belongs p s =
  match s with
    Rect (t,b) -> belongsRect p t b 
  | Circle (c,f) -> belongsCircle p c f
  | Union (l,r) -> belongs p l || belongs p r
  | Intersection (l,r) -> belongs p l && belongs p r
  | Subtraction (l,r) -> belongs p l && not(belongs p r)
;;





(* FUNCTION density*)
let rec density p s =
  match s with
    Rect (t,b) -> if belongs p s then 1 else 0
  | Circle (c,f) -> if belongs p s then 1 else 0
  | Union (l,r) -> density p l + density p r
  | Intersection (l,r) -> if (belongs p l && belongs p r) then density p l + density p r else 0
  | Subtraction (l,r) -> if (density p l - density p r)<0 then 0 else density p l - density p r
;;


(* FUNCTION which *)

let  rec which p s =
  match s with
    Rect (t,b) -> if belongs p s then [Rect (t,b)] else [] 
  | Circle (c,f) -> if belongs p s then [Circle (c,f)] else []
  | Union (l,r) -> if density p s >= 2 
    then (which p l)@(which p r) 
    else  if belongs p l then which p l else which p r
  | Intersection (l,r) -> if belongs p s then which p l @ which p r else []
  | Subtraction (l,r) -> if density p s = 0 then [] else which p l

(* FUNCTION minBound *)

let rec minBound s =
  match s with
    Rect (t,b) -> Rect(t,b)
  | Circle ((cx, cy),f) -> Rect((cx-.f, cy+.f) , (cx+.f, cy-.f))
  | Union (l,r) ->  Union(minBound l , minBound r)
  | Intersection (l,r) -> Intersection (minBound l , minBound r)
  | Subtraction (l,r) -> minBound l
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

