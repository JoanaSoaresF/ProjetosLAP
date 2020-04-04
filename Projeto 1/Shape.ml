(* Shape module body *)

(* 
Aluno 1: Goncalo Lourenco n55780
Aluno 2:  Joana Faria n55754

Comment:
Foram programadas todas as funcoes.
A funcao partition nao engloba todas as possibilidades uma vez que ha infinitas 
e algumas sao impossiveis de resolver. No entanto resolve grande parte dos casos

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

(* Checks if a point (px, py) belongs in the Rect(t,b) *)
let belongsRect (px, py) t b =
  match t, b with
    (tx, ty), (bx, by) -> px>=tx && py>=ty && px<=bx && py<=by
;;

(* Checks if a point (px, py) belongs in the Circle(c, f) *)
let belongsCircle (px, py) c f =
  match c with
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
  | Intersection (l,r) -> if (belongs p l && belongs p r) 
    then density p l + density p r 
    else 0
  | Subtraction (l,r) -> if belongs p r then 0 else density p l
;;


(* FUNCTION which *)

let  rec which p s =
  match s with
    Rect (t,b) -> if belongs p s then [Rect (t,b)] else [] 
  | Circle (c,f) -> if belongs p s then [Circle (c,f)] else []
  | Union (l,r) ->  (which p l)@(which p r) 
  | Intersection (l,r) -> if belongs p s then which p l @ which p r else []
  | Subtraction (l,r) -> if belongs p r  then [] else which p l

;;


(* FUNCTION minBound *)

(*Computes the minimum rectangle that includes all points given*)
let rec maxDimUnion  ((x1, y1) , (x2, y2)) ((x3, y3), (x4, y4)) = 
  ((min x1 x3 , min y1 y3), (max x2 x4, max y2 y4 ))
;;

(*Detects the minimum bounding rectangle that involves the shape s*)
let rec sizeRect s = 
  match s with 
    Rect (t,b) -> (t,b)
  | Circle ((cx, cy),f) -> ((cx-.f, cy-.f) , (cx+.f, cy+.f))
  | Union (l,r) 
  | Intersection (l,r) 
  | Subtraction (l,r) -> maxDimUnion (sizeRect l)  (sizeRect  r)

;;


let rec minBound s = match sizeRect s with
    (t,b) -> Rect(t,b)

;;


(* FUNCTION grid *)

(*Creates a line of union of n rectangles with dimensions axb. 
  c identifies the column to start creating the rectangle *)
let rec createLine m n a b c =  let mf = float_of_int m in 
  let cf = float_of_int c in 
  if (m mod 2)=0
  then (if c<n-2  
        then Union( 
            Rect(((cf)*.a, (mf-.1.)*.b), ((cf+.1.)*.a, mf*.b)), 
            createLine m n a b (c+2))
        else 
          Rect(((cf)*.a, (mf-.1.)*.b), ((cf+.1.)*.a, mf*.b)))
  else (if c<n-3
        then Union( 
            Rect(((cf+.1.)*.a, (mf-.1.)*.b), ((cf+.2.)*.a, mf*.b)), 
            createLine m n a b (c+2))
        else 
          Rect(((cf+.1.)*.a, (mf-.1.)*.b), ((cf+.2.)*.a, mf*.b)))

;;



let rec grid m n a b = if m = 1
  then createLine m n a b 0
  else Union((createLine m n a b 0), (grid (m-1) n a b))
;;


(* FUNCTION countBasicRepetitions *)

(*Count the number os repetitions of the element a in the list l*)
let rec count a l = match l with
    [] -> 0
  | x::xs -> (if x=a then 1 else 0) + count a xs
;;

(*List all the basic shapes in a shape*)
let rec listShapes s=
  match s with
    Rect (t,b) -> [Rect (t, b)]
  | Circle (c,f) -> [Circle (c, f)]
  | Union (l,r) 
  | Intersection (l,r)
  | Subtraction (l,r) -> (listShapes l)@(listShapes r)
;;

(* Checks the number of repetitions by cheching a n value of a list os tuples
   The n value indicates the number os repetitions of that element*)
let rec elementsRepeated l = match l with
    [] -> 0
  |(x,n)::xs -> (if n>1 then 1 else 0) + elementsRepeated xs
;;


let countBasicRepetitions s = let allShapes = listShapes s in 
  let rec occurences l = (*Computes a list of tuples (x, n) where x is the element and
                           n the number os times that the elemnent x occurs in the list l*)
    match l with
      [] -> []
    |x::xs -> (x, count x allShapes)::occurences xs

  in elementsRepeated (occurences allShapes)

;;


(* FUNCTION svg *)

(*Generates a unique id -function given by the professor Artur Dias*)
let  genID = 
  let idBase = ref 0 in
  fun () ->
    idBase := !idBase + 1;
    "id" ^ (Printf.sprintf "%04d" !idBase)
;;

(*Computes the box size of a shape, using the minBound function. 
  That size is built-in HTML code *)
let boxSize s = match minBound s with
    Rect ((x1, y1),(x2,y2)) ->" width='"^ string_of_float (x2)^
                              "' height='"^string_of_float(y2)^
                              "'>"
  | Circle (c,f) -> failwith "boundingBox"
  | Union (l,r) 
  | Intersection (l,r)
  | Subtraction (l,r) -> failwith "boundingBox"
;;

(*Computes the HTML code to represent the shape s*)
let  rec shapehtml s sub inter id=
  match s with
    Rect ((x1, y1),(x2,y2)) -> 
    "<rect x='"^string_of_float x1 ^ "' y='" ^ string_of_float y1 ^
    "' width='"^ string_of_float (x2-.x1)^
    "' height='"^string_of_float(y2-.y1)^
    "' style='fill:"^(if sub then "white" else "black")^
    (if inter then "' clip-path='url(#"^id^")"else "" )^
    "'/>"
  | Circle ((cx, cy), f) -> 
    "<circle cx='"^string_of_float cx^
    "' cy='"^string_of_float cy^
    "' r='"^string_of_float f ^ 
    "' style='fill: " ^ (if sub then "white" else "black")^
    (if inter then "' clip-path='url(#"^id^")" else "")^
    "'/>"
  | Union (l,r) -> shapehtml l sub inter id^shapehtml r sub inter id
  | Intersection (l,r) -> let newid = genID () in 
    "<defs><clipPath id='"^newid^"' >" ^ shapehtml r sub true id 
    ^ "</clipPath></defs>" ^ shapehtml l sub true newid
  | Subtraction (l,r) -> shapehtml l sub inter id^shapehtml r (not sub) inter id

;;

let svg s =
  "<!DOCTYPE html><html><body><svg "^ boxSize s ^ (shapehtml s false false "")            
  ^" </svg></body></html>"
;;


(* FUNCTION partition *)

(*Checks if two rectangles are separated *)
let rectApart ((tx1,ty1),(bx1,by1)) ((tx2,ty2),(bx2,by2)) =
  tx1>=bx2 || bx1<=tx2 || ty1>=by2 || by1<=ty2
;;

(*Checks if two circles are separated *)
let circleApart ((cx1,cy1),f1) ((cx2,cy2),f2) =
  Pervasives.sqrt(((cx1-.cx2)*.(cx1-.cx2)) +. ((cy1-.cy2)*.(cy2-.cy2)))>(f1+.f2)
;;

(*Checks if a circle touches a line *)
let circleTouchLine ((cx,cy),f) xy =
  0.<(3.*.(cx*.cx)+.4.*.((xy*.xy)+.(xy*.cy)+.(cy*.cy)-.(f*.f)))
;;
(*Checks if a circle intersects a line between points a and b*)
let circleTouchLineBetweenAB  ((cx,cy),f) xy a b =
  ((a>(cx+.Pervasives.sqrt(cx*.cx-.4.*.((cx*.cx)+.(xy-.cy)*.(xy-.cy)-.(f*.f))))/.2.) 
   || (b<(cx+.Pervasives.sqrt(cx*.cx-.4.*.((cx*.cx)+.(xy-.cy)*.(xy-.cy)-.(f*.f))))/.2.)) 
  && ((a>(cx-.Pervasives.sqrt(cx*.cx-.4.*.((cx*.cx)+.(xy-.cy)*.(xy-.cy)-.(f*.f))))/.2.) 
      || (b<(cx-.Pervasives.sqrt(cx*.cx-.4.*.((cx*.cx)+.(xy-.cy)*.(xy-.cy)-.(f*.f))))/.2.))
;;

(*Checks if a circle does not intersect a rectangle*)
let cApartR ((cx,cy),f) ((tx,ty),(bx,by))=
  not(belongsRect (cx,cy) (tx,ty) (bx,by)) &&
  (if (circleTouchLine ((cx,cy),f) ty) 
   then true 
   else 
     circleTouchLineBetweenAB ((cx,cy),f) ty tx bx) &&
  (if(circleTouchLine ((cx,cy),f) by) 
   then true 
   else
     circleTouchLineBetweenAB ((cx,cy),f) by tx bx) &&
  (if(circleTouchLine ((cx,cy),f) tx) 
   then true 
   else
     circleTouchLineBetweenAB ((cx,cy),f) tx ty by) && 
  (if (circleTouchLine ((cx,cy),f) bx) 
   then true 
   else
     circleTouchLineBetweenAB ((cx,cy),f) bx ty by)

;;

(*Checks if two shapes intersect*)
let rec touch s1 s2=
  match (s1, s2) with
    (Rect (t1,b1), Rect(t2,b2)) -> not (rectApart (t1,b1) (t2,b2))
  | (Circle (c,f), Rect (t,b)) -> not (cApartR (c,f) (t,b))
  | (Rect (t,b), Circle (c,f)) -> not (cApartR (c,f) (t,b))
  | (Circle (c1,f1), Circle(c2,f2)) -> not (circleApart (c1,f1) (c2,f2))
  | (Union (l,r), Rect (t,b)) -> touch s2 l || touch s2 r
  | (Rect(t,b), Union(l,r)) -> touch s1 l || touch s1 r
  | (Intersection (l,r), Rect (t,b)) -> touch s2 l && touch s2 r
  | (Rect (t,b), Intersection (l,r)) -> touch s1 l && touch s1 r
  | (Subtraction (l,r), Rect (t,b)) -> touch s2 l && not(touch s2 r)
  | (Rect (t,b), Subtraction (l,r)) -> touch s1 l && not(touch s1 r)
  | (Union (l,r), Circle (c,f)) -> touch s2 l || touch s2 r
  | (Circle (c,f), Union (l,r)) -> touch s1 l || touch s1 r
  | (Intersection (l,r), Circle (c,f)) -> touch s2 l && touch s2 r
  | (Circle (c,f), Intersection (l,r)) -> touch s1 l && touch s1 r
  | (Subtraction (l,r), Circle (c,f)) -> touch s2 l && not(touch s2 r)
  | (Circle (c,f), Subtraction (l,r)) -> touch s1 l && not(touch s1 r)
  | (Union (l1,r1), Union (l2,r2)) -> 
    touch l1 l2 || touch l1 r2 || touch r1 l2 || touch r1 r2
  | (Intersection (l2,r2), Union (l1,r1)) -> 
    (touch l1 l2 || touch l1 r2) && (touch r1 l2 || touch r1 r2)
  | (Union (l1,r1), Intersection (l2,r2)) -> 
    (touch l1 l2 || touch l1 r2) && (touch r1 l2 || touch r1 r2)
  | (Subtraction (l2,r2), Union (l1,r1))-> 
    (touch l1 l2 && not(touch l1 r2)) || (touch r1 l2 && not(touch r1 r2))
  | (Union (l1,r1), Subtraction (l2,r2)) -> 
    (touch l1 l2 && not(touch l1 r2)) || (touch r1 l2 && not(touch r1 r2))
  | (Intersection (l1,r1), Intersection (l2,r2)) ->
    touch l1 l2 && touch l1 r2 && touch r1 l2 && touch r1 r2
  | (Subtraction (l2,r2), Intersection (l1,r1)) -> 
    (touch l1 l2 && not(touch l1 r2)) && (touch r1 l2 && not(touch r1 r2))
  | (Intersection (l1,r1), Subtraction (l2,r2)) -> 
    (touch l1 l2 && not(touch l1 r2)) && (touch r1 l2 && not(touch r1 r2))
  | (Subtraction (l1,r1), Subtraction (l2,r2)) -> 
    touch l1 l2 && not(touch l1 r2) && not(touch r1 l2) 
;;

(*This function has limitations, does not work for all cases:



*)
let rec partition s =
  match s with
    Rect (t,b) -> [Rect (t, b)]
  | Circle (c,f) -> [Circle (c, f)]
  | Union (l,r) -> 
    (if (touch l r) then [Union(l,r)] else (partition l)@(partition r))
  | Intersection (l,r) -> [Intersection (l,r)]
  | Subtraction (l,r) -> [Subtraction (l,r)]


;;