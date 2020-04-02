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

let rect1 = Rect ((0.0, 0.0), (5.0, 2.0))
let rect2 = Rect ((2.0, 2.0), (7.0, 7.0))
let shape1 = Union (rect1, rect2);;
let shape2 = Union (rect1, rect1);;

let shape3 = Union(shape1, shape1);;


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
let rec maxDimUnion  ((x1, y1) , (x2, y2)) ((x3, y3), (x4, y4)) = 
  ((min x1 x3 , min y1 y3), (max x2 x4, max y2 y4 ))
;;


let rec sizeRect s = 
  match s with 
    Rect (t,b) -> (t,b)
  | Circle ((cx, cy),f) -> ((cx-.f, cy+.f) , (cx+.f, cy-.f))
  | Union (l,r) 
  | Intersection (l,r) 
  | Subtraction (l,r) -> maxDimUnion (sizeRect l)  (sizeRect  r)

;;

let rec minBound s = match sizeRect s with
    (t,b) -> Rect(t,b)

;;
(* FUNCTION grid *)

let rec createLine m n a b  =  let mf = float_of_int m in let nf = float_of_int n in 
  if not((m mod 2)=0)
  then (if n>2  
        then Union( Rect(((nf-.2.)*.a, (mf-.1.)*.b), ((nf-.1.)*.a, mf*.b)), createLine m (n-2) a b)
        else Rect(((nf-.2.)*.a, (mf-.1.)*.b), ((nf-.1.)*.a, mf*.b)))
  else (if n>2  
        then Union( Rect(((nf-.1.)*.a, (mf-.1.)*.b), (nf*.a, mf*.b)), createLine m (n-2) a b)
        else Rect(((nf-.1.)*.a, (mf-.1.)*.b), (nf*.a, mf*.b)))

;;

let rec grid m n a b = if m = 1
  then createLine m n a b
  else Union((createLine m n a b), (grid (m-1) n a b))
;;


(* FUNCTION countBasicRepetitions *)



let rec count a l = match l with
    [] -> 0
  | x::xs -> (if x=a then 1 else 0) + count a xs;;

let rec listShapes s=
  match s with
    Rect (t,b) -> [Rect (t, b)]
  | Circle (c,f) -> [Circle (c, f)]
  | Union (l,r) 
  | Intersection (l,r)
  | Subtraction (l,r) -> (listShapes l)@(listShapes r)
;;

let rec elementsRepeated l = match l with
    [] -> 0
  |(x,n)::xs -> (if n>1 then 1 else 0) + elementsRepeated xs
;;


let countBasicRepetitions s = let allShapes = listShapes s in 
  let rec occurences l =
    match l with
      [] -> []
    |x::xs -> (x, count x allShapes)::occurences xs

  in elementsRepeated (occurences allShapes)

;;

let shape4 = Subtraction(shape2, rect1);;


(* FUNCTION svg *)

let  genID = 
  let idBase = ref 0 in
  fun () ->
    idBase := !idBase + 1;
    "id" ^ (Printf.sprintf "%04d" !idBase)
;;
let boxSize s = match minBound s with
    Rect ((x1, y1),(x2,y2)) ->" width='"^ string_of_float (x2)^
                              "' height='"^string_of_float(y2)^
                              "'>"
  | Circle (c,f) -> failwith "boundingBox"
  | Union (l,r) 
  | Intersection (l,r)
  | Subtraction (l,r) -> failwith "boundingBox"
;;

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
    (if inter then "' clip-path='url(#"^id^")'" else "")^
    "'/>"
  | Union (l,r) -> shapehtml l false false "id"^shapehtml r false false ""
  | Intersection (l,r) -> let id = genID () in 
    "<defs><clipPath id='"^id^"' >" ^ shapehtml r false false id
    ^ "</clipPath></defs>" ^ shapehtml l false true id
  | Subtraction (l,r) -> shapehtml l false false ""^shapehtml r true false ""

let svg s =
  "<!DOCTYPE html><html><body><svg "^ boxSize s ^ (shapehtml s false false "")            
  ^" </svg></body></html>"
;;



(* FUNCTION partition *)

let rectApart ((tx1,ty1),(bx1,by1)) ((tx2,ty2),(bx2,by2)) =
  tx1>=bx2 || bx1<=tx2 || ty1>=by2 || by1<=ty2
;;

let circleApart ((cx1,cy1),f1) ((cx2,cy2),f2) =
  Pervasives.sqrt(((cx1-.cx2)*.(cx1-.cx2)) +. ((cy1-.cy2)*.(cy2-.cy2)))>(f1+.f2)
;;

let cApartR ((cx,cy),f) ((tx,ty),(bx,by))=
  not(belongsRect (cx,cy) (tx,ty) (bx,by)) &&
  (if (0.<(3.*.(cx*.cx)+.4.*.((ty*.ty)+.(ty*.cy)+.(cy*.cy)-.(f*.f)))) then true 
   else
     ((tx>(cx+.Pervasives.sqrt(cx*.cx-.4.*.((cx*.cx)+.(ty-.cy)*.(ty-.cy)-.(f*.f))))/.2.) 
      || (bx<(cx+.Pervasives.sqrt(cx*.cx-.4.*.((cx*.cx)+.(ty-.cy)*.(ty-.cy)-.(f*.f))))/.2.)) 
     && ((tx>(cx-.Pervasives.sqrt(cx*.cx-.4.*.((cx*.cx)+.(ty-.cy)*.(ty-.cy)-.(f*.f))))/.2.) 
         || (bx<(cx-.Pervasives.sqrt(cx*.cx-.4.*.((cx*.cx)+.(ty-.cy)*.(ty-.cy)-.(f*.f))))/.2.)))&&
  (if(0.<(3.*.(cx*.cx)+.4.*.((by*.by)+.(by*.cy)+.(cy*.cy)-.(f*.f)))) then true 
   else
     ((tx>(cx+.Pervasives.sqrt(cx*.cx-.4.*.((cx*.cx)+.(by-.cy)*.(by-.cy)-.(f*.f))))/.2.) 
      || (bx<(cx+.Pervasives.sqrt(cx*.cx-.4.*.((cx*.cx)+.(by-.cy)*.(by-.cy)-.(f*.f))))/.2.)) 
     && ((tx>(cx-.Pervasives.sqrt(cx*.cx-.4.*.((cx*.cx)+.(by-.cy)*.(by-.cy)-.(f*.f))))/.2.) 
         || (bx<(cx-.Pervasives.sqrt(cx*.cx-.4.*.((cx*.cx)+.(by-.cy)*.(by-.cy)-.(f*.f))))/.2.))) &&
  (if(0.<(3.*.(cy*.cy)+.4.*.((tx*.tx)+.(tx*.cx)+.(cx*.cx)-.(f*.f)))) then true 
   else
     ((ty>(cy+.Pervasives.sqrt(cy*.cy-.4.*.((cy*.cy)+.(tx-.cx)*.(tx-.cx)-.(f*.f))))/.2.) 
      || (by<(cx+.Pervasives.sqrt(cy*.cy-.4.*.((cy*.cy)+.(tx-.cx)*.(tx-.cx)-.(f*.f))))/.2.)) 
     && ((ty>(cy-.Pervasives.sqrt(cy*.cy-.4.*.((cy*.cy)+.(tx-.cx)*.(tx-.cx)-.(f*.f))))/.2.) 
         || (by<(cx-.Pervasives.sqrt(cy*.cy-.4.*.((cy*.cy)+.(tx-.cx)*.(tx-.cx)-.(f*.f)))/.2.)))) && 
  (if (0.<(3.*.(cy*.cy)+.4.*.((bx*.bx)+.(bx*.cx)+.(cx*.cx)-.(f*.f)))) then true 
   else
     ((ty>(cy+.Pervasives.sqrt(cy*.cy-.4.*.((cy*.cy)+.(bx-.cx)*.(bx-.cx)-.(f*.f))))/.2.) 
      || (by<(cx+.Pervasives.sqrt(cy*.cy-.4.*.((cy*.cy)+.(bx-.cx)*.(bx-.cx)-.(f*.f))))/.2.)) 
     && ((ty>(cy-.Pervasives.sqrt(cy*.cy-.4.*.((cy*.cy)+.(bx-.cx)*.(bx-.cx)-.(f*.f))))/.2.) 
         || (by<(cx-.Pervasives.sqrt(cy*.cy-.4.*.((cy*.cy)+.(bx-.cx)*.(bx-.cx)-.(f*.f))))/.2.)))

;;

let rec touch s1 s2=
  match (s1, s2) with
    (Rect (t1,b1), Rect(t2,b2)) -> rectApart (t1,b1) (t2,b2)
  | (Circle (c,f), Rect (t,b)) 
  | (Rect (t,b), Circle (c,f)) -> cApartR (c,f) (t,b)
  | (Circle (c1,f1), Circle(c2,f2)) -> circleApart (c1,f1) (c2,f2)
  | (Union (l,r), Rect (t,b))
  | (Rect (t,b), Union (l,r)) -> (touch (t,b) l) || (touch (t,b) r)
  | (Intersection (l,r), Rect (t,b))
  | (Rect (t,b), Intersection (l,r)) -> touch (Rect (t,b)) l && touch (Rect (t,b)) r
  | (Subtraction (l,r), Rect (t,b))
  | (Rect (t,b), Subtraction (l,r)) -> touch (Rect (t,b)) l && not(touch (Rect (t,b)) r)
  | (Union (l,r), Circle (c,f))
  | (Circle (c,f), Union (l,r)) -> touch (Circle (c,f)) l || touch (Circle (c,f)) r
  | (Intersection (l,r), Circle (c,f))
  | (Circle (c,f), Intersection (l,r)) -> touch (Circle (c,f)) l && touch (Circle (c,f)) r
  | (Subtraction (l,r), Circle (c,f))
  | (Circle (c,f), Subtraction (l,r)) -> touch (Circle (c,f)) l && not(touch (Circle (c,f)) r)
  | (Union (l1,r1), Union (l2,r2)) -> touch l1 l2 || touch l1 r2 || touch r1 l2 || touch r1 r2
  | (Intersection (l2,r2), Union (l1,r1))
  | (Union (l1,r1), Intersection (l2,r2)) -> (touch l1 l2 || touch l1 r2) && (touch r1 l2 || touch r1 r2)
  | (Subtraction (l2,r2), Union (l1,r1))
  | (Union (l1,r1), Subtraction (l2,r2)) -> (touch l1 l2 && not(touch l1 r2)) || (touch r1 l2 && not(touch r1 r2))
  | (Intersection (l1,r1), Intersection (l2,r2)) -> touch l1 l2 && touch l1 r2 && touch r1 l2 && touch r1 r2) 
| (Subtraction (l2,r2), Intersection (l1,r1))
| (Intersection (l1,r1), Subtraction (l2,r2)) -> (touch l1 l2 && not(touch l1 r2)) && (touch r1 l2 && not(touch r1 r2))
| (Subtraction (l1,r1), Subtraction (l2,r2)) -> touch l1 l2 && not(touch l1 r2) && not(touch r1 l2)   )
;;




let partition s =
  match s with
    Rect (t,b) -> [Rect (t, b)]
  | Circle (c,f) -> [Circle (c, f)]
  | Union (l,r) -> if (touch l r) then Union(l,r) else partition l :: partition r
  | Intersection (l,r) -> [Intersection (l,r)]
  | Subtraction (l,r) -> [Subtraction (l,r)]


;;