(** {5 Old fashion positions } *)
type pos = string * int * int
val no_pos : pos
val pos_of_lex_pos : Lexing.position -> pos
val fn : pos -> string
val ln : pos -> int
val cn : pos -> int

(** {5 Combinators on primitive types *)
val iteri : (int -> unit) -> int -> unit
val array_map_of_list : ('a -> 'b) -> 'a list -> 'b array
val array_fold_left_mapi :
  (int -> 'a -> 'b -> 'a * 'c) -> 'a -> 'b array -> 'a * 'c array
val array_fold_left2 :
  ('a -> 'b -> 'c -> 'a) -> 'a -> 'b array -> 'c array -> 'a

(** {5 Utilities on files } *)
val kasim_open_out : string -> out_channel
val open_out_fresh_filename : string -> string list -> string -> out_channel
val kasim_path : string -> string

(** {5 Misc utilities } *)
val bit_rep_size : int -> int (**number of bits used to represent n in base 2*)
val pow : int -> int -> int
val pow64 : Int64.t -> Int64.t -> Int64.t
val read_input : unit -> string
val replace_space : string -> string
val mk_dir_r : string -> unit