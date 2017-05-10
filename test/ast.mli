(** Abstracted OCaml AST *)

type arg_label
type expression

(** Builders *)
module B : sig
  val nolabel : arg_label
  val labelled : string -> arg_label
  val optional : string -> arg_label

  val pexp_apply
    :  loc : Location.t
    -> expression
    -> (arg_label * expression) list
    -> expression

  val pexp_ident
    :  loc : Location.t
    -> Longident.t Asttypes.loc
    -> expression
end

(** Patterns *)
module P : sig
  val nolabel : (arg_label, 'a, 'a) View_pattern.t
  val labelled
    :  (string, 'a, 'b) View_pattern.t
    -> (arg_label, 'a, 'b) View_pattern.t
  val optional
    :  (string, 'a, 'b) View_pattern.t
    -> (arg_label, 'a, 'b) View_pattern.t

  val pexp_apply
    :  (expression, 'a, 'b) View_pattern.t
    -> ((arg_label * expression) list, 'b, 'c) View_pattern.t
    -> (expression, 'a, 'c) View_pattern.t

  val pexp_ident
    :  (Longident.t Asttypes.loc, 'a, 'b) View_pattern.t
    -> (expression, 'a, 'b) View_pattern.t

  val pexp_loc
    :  (Location.t, 'a, 'b) View_pattern.t
    -> (expression, 'b, 'c) View_pattern.t
    -> (expression, 'a, 'c) View_pattern.t
end
