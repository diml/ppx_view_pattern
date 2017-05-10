(** Abstracted OCaml AST *)
module Ast : sig
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
end = struct
  open Migrate_parsetree.Ast_404
  open Asttypes
  open Parsetree

  type nonrec arg_label = arg_label
  type nonrec expression = expression

  module B = struct
    let nolabel = Nolabel
    let labelled s = Labelled s
    let optional s = Optional s

    let pexp_apply ~loc f args =
      { pexp_loc = loc
      ; pexp_attributes = []
      ; pexp_desc = Pexp_apply (f, args)
      }

    let pexp_ident ~loc id =
      { pexp_loc = loc
      ; pexp_attributes = []
      ; pexp_desc = Pexp_ident id
      }
  end

  module P = struct
    open View_pattern.Match_result

    let nolabel x l =
      match x with
      | Nolabel -> Ok l
      | _ -> Match_failure

    let labelled t x l =
      match x with
      | Labelled s -> t s l
      | _ -> Match_failure

    let optional t x l =
      match x with
      | Optional s -> t s l
      | _ -> Match_failure

    let pexp_apply tf targs x l =
      match x.pexp_desc with
      | Pexp_apply (f, args) -> begin
          match tf f l with
          | Match_failure -> Match_failure
          | Ok l -> targs args l
        end
      | _ -> Match_failure

    let pexp_ident t x l =
      match x.pexp_desc with
      | Pexp_ident id -> t id l
      | _ -> Match_failure

    let pexp_loc tloc t x l =
      match tloc x.pexp_loc l with
      | Ok l -> t x l
      | Match_failure -> Match_failure
  end
end

open Ast

let () =
  let loc = Location.none in
  let e =
    B.(pexp_apply ~loc (pexp_ident ~loc { loc; txt = Lident "+" })
         [ nolabel, (pexp_ident ~loc { loc; txt = Lident "x" })
         ; nolabel, (pexp_ident ~loc { loc; txt = Lident "y" })
         ])
  in

  begin
    (* Simple matching *)
    match%vpat e with
    | P.(Pexp_apply (Pexp_ident id1,
                     [ Nolabel, Pexp_ident id2
                     ; Nolabel, Pexp_ident id3 ])) ->
      ignore (id1 : Longident.t Asttypes.loc);
      ignore (id2 : Longident.t Asttypes.loc);
      ignore (id3 : Longident.t Asttypes.loc)
    | _ ->
      assert false
  end;

  begin
    (* Capturing the location as well *)
    match%vpat e with
    | P.(Pexp_loc (loc,
                   Pexp_apply (Pexp_ident _,
                               [ Nolabel, Pexp_ident _
                               ; Nolabel, Pexp_ident _ ]))) ->
      ignore (loc : Location.t)
    | _ ->
      assert false
  end;
