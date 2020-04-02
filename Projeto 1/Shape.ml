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
let rect1 = Rect ((1., 1.), (5., 5.)) ;;
let rect2 = Rect ((2.0, 2.0), (7.0, 7.0)) ;;
let rect3 = Rect ((3., 3.), (4., 4.)) ;;
let circle1 = Circle ((1.0, 1.0), 1.) ;;
let circle2 = Circle ((6.0, 5.0), 3.) ;;
let shape1 = Union (rect1, rect2) ;;
let shape2 = Union (shape1, shape1) ;;
let shape3 = Union (circle1, shape2) ;;
let shape4 = Intersection(shape1, circle2);;
let shape5 = Subtraction(circle2, shape4);;


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
  | Circle ((cx, cy),f) -> ((cx-.f, cy-.f) , (cx+.f, cy+.f))
  | Union (l,r) 
  | Intersection (l,r) 
  | Subtraction (l,r) -> maxDimUnion (sizeRect l)  (sizeRect  r)

;;

let rec minBound s = match sizeRect s with
    (t,b) -> Rect(t,b)

;;
(* FUNCTION grid *)

let rec createLine m n a b c =  let mf = float_of_int m in let cf = float_of_int c in 
  if not((m mod 2)=0)
  then (if c<n-3  
        then Union( Rect(((cf+.1.)*.a, (mf-.1.)*.b), ((cf+.2.)*.a, mf*.b)), createLine m n a b (c+2))
        else Rect(((cf+.1.)*.a, (mf-.1.)*.b), ((cf+.2.)*.a, mf*.b)))
  else (if c<n-2  
        then Union( Rect(((cf)*.a, (mf-.1.)*.b), ((cf+.1.)*.a, mf*.b)), createLine m n a b (c+2))
        else Rect(((cf)*.a, (mf-.1.)*.b), ((cf+.1.)*.a, mf*.b)))

;;

let rec grid m n a b = if m = 1
  then createLine m n a b 0
  else Union((createLine m n a b 0), (grid (m-1) n a b))
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
  | Union (l,r) -> shapehtml l sub inter id^shapehtml r sub inter id
  | Intersection (l,r) -> let id = genID () in 
    "<defs><clipPath id='"^id^"' >" ^ shapehtml r sub false id
    ^ "</clipPath></defs>" ^ shapehtml l sub true id
  | Subtraction (l,r) -> shapehtml l false inter ""^shapehtml r true inter ""


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
  | (Circle (c,f), Rect (t,b)) -> cApartR (c,f) (t,b)
  | (Rect (t,b), Circle (c,f)) -> cApartR (c,f) (t,b)
  | (Circle (c1,f1), Circle(c2,f2)) -> circleApart (c1,f1) (c2,f2)
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
  | (Union (l1,r1), Union (l2,r2)) -> touch l1 l2 || touch l1 r2 || touch r1 l2 || touch r1 r2
  | (Intersection (l2,r2), Union (l1,r1)) -> (touch l1 l2 || touch l1 r2) && (touch r1 l2 || touch r1 r2)
  | (Union (l1,r1), Intersection (l2,r2)) -> (touch l1 l2 || touch l1 r2) && (touch r1 l2 || touch r1 r2)
  | (Subtraction (l2,r2), Union (l1,r1))-> (touch l1 l2 && not(touch l1 r2)) || (touch r1 l2 && not(touch r1 r2))
  | (Union (l1,r1), Subtraction (l2,r2)) -> (touch l1 l2 && not(touch l1 r2)) || (touch r1 l2 && not(touch r1 r2))
  | (Intersection (l1,r1), Intersection (l2,r2)) -> touch l1 l2 && touch l1 r2 && touch r1 l2 && touch r1 r2
  | (Subtraction (l2,r2), Intersection (l1,r1)) -> (touch l1 l2 && not(touch l1 r2)) && (touch r1 l2 && not(touch r1 r2))
  | (Intersection (l1,r1), Subtraction (l2,r2)) -> (touch l1 l2 && not(touch l1 r2)) && (touch r1 l2 && not(touch r1 r2))
  | (Subtraction (l1,r1), Subtraction (l2,r2)) -> touch l1 l2 && not(touch l1 r2) && not(touch r1 l2) 
;;




let rec partition s =
  match s with
    Rect (t,b) -> [Rect (t, b)]
  | Circle (c,f) -> [Circle (c, f)]
  | Union (l,r) -> (if (touch l r) then [Union(l,r)] else (partition l)@(partition r))
  | Intersection (l,r) -> [Intersection (l,r)]
  | Subtraction (l,r) -> [Subtraction (l,r)]


;;