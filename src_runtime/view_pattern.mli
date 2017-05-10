module Match_result : sig
  type 'a t =
    | Ok of 'a
    | Match_failure
end

(** Heterogeneous lists *)
module HList : sig
  type 'a t =
    | [] : unit t
    | ( :: ) : 'a * 'b t -> ('a ->  'b) t
end

(** Type of a view pattern: it is a function that takes an input value of type ['a], a
    list of captured values and return a new list of captured values, or a match
    failure. *)
type ('a, 'b, 'c) t = 'a -> 'b HList.t -> 'c HList.t Match_result.t

(** Execute a view pattern on some input. [loc] is a triple [(filename, line, column)] *)
val exec_exn : ('a, unit, 'b -> unit) t -> loc:(string * int * int) -> 'a -> 'b

(** [__] is a view pattern that captures its input *)
val __ : ('a, 'b, 'a -> 'b) t

(** [alt l] is a view pattern that tries the input on all patterns in [l], until one
    succeeds *)
val alt : ('a, 'b, 'c) t list -> ('a, 'b, 'c) t

(** Map the result of a view pattern *)
val map : ('a, 'b, 'c) t -> f:('c HList.t -> 'd) -> ('a, 'b, 'd -> unit) t

(** Matches the empty list *)
val nil : (_ list, 'a, 'a) t

(** Matches a list of a least one element *)
val cons : ('a, 'b, 'c) t -> ('a list, 'c, 'd) t -> ('a list, 'b, 'd) t

val t2
  :  ('a1, 'b, 'c) t
  -> ('a2, 'c, 'd) t
  -> ('a1 * 'a2, 'b, 'd) t

val t3
  :  ('a1, 'b, 'c) t
  -> ('a2, 'c, 'd) t
  -> ('a3, 'd, 'e) t
  -> ('a1 * 'a2 * 'a3, 'b, 'e) t
