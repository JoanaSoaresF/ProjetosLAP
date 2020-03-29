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

let rec belongs p s =
    match s with
    Rect (t,b) -> between p t b 
    | Circle (c,f) -> belongC p c f
    | Union (l,r) -> belongs p l || belongs p r
    | Intersection (l,r) -> belongs p l && belongs p r
    | Subtraction (l,r) -> belongs p l && not(belongs p r)
;;

let between p t b =
    match p with
        (px, py) -> match t with
                        (tx, ty) -> if px>=tx && py>=ty then
                                        match b with
                                            (bx, by) -> px<=bx && py<=by
                                    else
                                        false
;;

let belongC p c f =
    match p with
    (px, py) -> match t with
                    (tx, ty) -> Pervasives.sqrt(((px-tx)*(px-tx)) + ((py-ty)*(py-ty)))<=f
;;



(* FUNCTION density
    Teu amor, teste
    com muito amor
    imenso
    imenso
    imenso
    imenso
    imensoooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo *)

let rec density p s =
    match s with
    Rect (t,b) -> if between p t b then 1 else 0
    | Circle (c,f) -> if belongC p c f then 1 else 0
    | Union (l,r) -> desity p l + density p r
    | Intersection (l,r) -> if (belongs p l && belongs p r) then desity p l + density p r else 0
    | Subtraction (l,r) -> if (density p l - density p r)<0 then 0 else density p l - density p r
;;


(* FUNCTION which *)

let  rec which p s =
    match s with
    Rect (t,b) -> if between p t b then [Rect (t,b)] else [] 
    | Circle (c,f) -> if belongC p c f then [Circle (c,f)] else []
    | Union (l,r) -> which p l @ which p r
    | Intersection (l,r) -> if (belongs p l && belongs p r) then which p l @ which p r else []
    | Subtraction (l,r) -> if (density p l - density p r)<0 then [] else which p l @ which p r(*quais os sólidos a retirar??*)(**tirar adjoin*))
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

