module Match_result = struct
  type 'a t =
    | Ok of 'a
    | Match_failure
end

module HList = struct
  type 'a t =
    | [] : unit t
    | ( :: ) : 'a * 'b t -> ('a ->  'b) t
end

open Match_result

type ('a, 'b, 'c) t = 'a -> 'b HList.t -> 'c HList.t Match_result.t

let __ x l = Ok HList.(x :: l)

let rec alt ts x l =
  match ts with
  | [] -> Match_failure
  | t :: ts ->
    match t x l with
    | Ok _ as res -> res
    | Match_failure -> alt ts x l

let map t ~f x l =
  match t x l with
  | Ok x -> Ok HList.[f x]
  | Match_failure -> Match_failure

let nil x l =
  match x with
  | [] -> Ok l
  | _  -> Match_failure

let cons t_hd t_tl x l =
  match x with
  | [] -> Match_failure
  | hd :: tl ->
    match t_hd hd l with
    | Ok l -> t_tl tl l
    | Match_failure -> Match_failure

let exec_exn t ~loc:(fn, lnum, cnum) x =
  let open HList in
  match t x [] with
  | Ok [x] -> x
  | Match_failure ->
    raise (Match_failure (fn, lnum, cnum))

let t2 t1 t2 (x1, x2) l =
  match t1 x1 l with
  | Match_failure -> Match_failure
  | Ok l -> t2 x2 l

let t3 t1 t2 t3 (x1, x2, x3) l =
  match t1 x1 l with
  | Match_failure -> Match_failure
  | Ok l ->
    match t2 x2 l with
    | Match_failure -> Match_failure
    | Ok l -> t3 x3 l
