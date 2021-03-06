{
  open Lexing
  open KappaParser
  open ExceptionDefn

  let reach_eof lexbuf =
    lexbuf.lex_eof_reached <- true

 let reset_eof lexbuf =
   lexbuf.lex_eof_reached <- false

 let position lexbuf =
   let pos = lexbuf.lex_curr_p in
   (pos.pos_fname, pos.pos_lnum, pos.pos_cnum - pos.pos_bol)

 let keyword_or_id =
 let keywords = Hashtbl.create 15 in
 let () = Hashtbl.add keywords "do" DO in
 let () = Hashtbl.add keywords "set" SET in
 let () = Hashtbl.add keywords "repeat" REPEAT in
 let () = Hashtbl.add keywords "until" UNTIL in
 let () = Hashtbl.add keywords "INF" INFINITY in
 fun x ->
 try Hashtbl.find keywords x with Not_found -> ID x
}

let eol = '\r'? '\n'
let blank = [' ' '\t']
let integer = (['0'-'9']+)
let real =
  '-'?
     (((['0'-'9']+ | ['0'-'9']+ '.' ['0'-'9']* ) | (['0'-'9']* '.' ['0'-'9']+))
	((['e' 'E'] ['+' '-'] ['0'-'9']+) | (['e' 'E'] ['0'-'9']+)))
  | ((['0'-'9']+ '.' ['0'-'9']* ) | (['0'-'9']* '.' ['0'-'9']+))
let id = (['a'-'z' 'A'-'Z'] ['a'-'z' 'A'-'Z' '0'-'9' '_' '-' '+']* )
let internal_state = '~' (['0'-'9' 'a'-'z' 'A'-'Z']+)
let pert = '$' id

rule token = parse
	 | '\\' eol {Lexing.new_line lexbuf ; token lexbuf}
	 | "&&" {AND}
	 | "||" {OR}
	 | "<->" {KAPPA_LRAR}
	 | "->" {KAPPA_RAR}
	 | "<-" {LAR}
	 | ":=" {let pos = position lexbuf in ASSIGN pos}
	 | "<>" {DIFF}
	 | pert as s {let pos = position lexbuf in
		      match s with
		      | "$DEL" -> (DELETE pos)
		      | "$ADD" -> (INTRO pos)
		      | "$SNAPSHOT" -> (SNAPSHOT pos)
		      | "$STOP" -> (STOP pos)
		      | "$FLUX" -> (FLUX pos)
		      | "$TRACK" -> (TRACK pos)
		      | "$UPDATE" -> (ASSIGN2 pos)
		      | "$PRINT" -> (PRINT pos)
		      | "$PRINTF" -> (PRINTF pos)
		      | "$PLOTENTRY" -> PLOTENTRY
		      | s ->
			 raise
			   (Syntax_Error
			      ("Perturbation effect \""^s^"\" is not defined",
			       (Lexing.lexeme_start_p lexbuf,
				Lexing.lexeme_end_p lexbuf)))
		     }
	 | '[' {let lab = read_label [] [']'] lexbuf in
		match lab with
		| "E" -> EVENT
		| "E+" -> PROD_EVENT
		| "E-" -> NULL_EVENT
		| "T" -> TIME
		| "Tsim" -> CPUTIME
		| "log" -> LOG
		| "sin" -> SINUS
		| "cos" -> COSINUS
		| "tan" -> TAN
		| "exp" -> EXPONENT
		| "int" -> ABS
		| "mod" -> MODULO
		| "sqrt" -> SQRT
		| "true" -> TRUE
		| "false" -> FALSE
		| "pi" -> FLOAT (3.14159265)
		| "max" -> MAX
		| "min" -> MIN
		| "Emax" -> EMAX
		| "Tmax" -> TMAX
		| "p" -> PLOTNUM
		| _ as s ->
		   raise (Syntax_Error
			    ("Symbol \""^s^"\" is not defined",
			     (Lexing.lexeme_start_p lexbuf,
			      Lexing.lexeme_end_p lexbuf)))
	       }
	 | ':' {TYPE}
	 | ';' {SEMICOLON}
	 | '\"' {let str = read_label [] ['\"'] lexbuf in
		 let pos = position lexbuf in STRING (str,pos)}
	 | eol {Lexing.new_line lexbuf ; NEWLINE}
	 | '#' {comment lexbuf}
	 | '/' '*' {inline_comment lexbuf; token lexbuf}
	 | integer as n {INT (int_of_string n)}
	 | real as f {FLOAT (float_of_string f)}
	 | '\'' ([^'\n''\'']+ as x) '\''{LABEL(x)}
	 | id as str {keyword_or_id str}
	 | '@' {AT}
	 | ',' {COMMA}
	 | '(' {OP_PAR}
	 | ')' {CL_PAR}
	 | '{' {OP_CUR}
	 | '}' {CL_CUR}
	 | '|' {let pos = position lexbuf in PIPE pos}
	 | '.' {DOT}
	 | '+' {PLUS}
	 | '*' {MULT}
	 | '-' {MINUS}
	 | '^' {POW}
	 | '/' {DIV}
	 | '<' {SMALLER}
	 | '>' {GREATER}
	 | '=' {EQUAL}
	 | '%' {let lab = read_label [] [':'] lexbuf in
		let pos = position lexbuf in
		match lab with
		| "agent" -> (SIGNATURE pos)
		| "init" -> (INIT pos)
		| "var" -> (LET pos)
		| "plot" -> (PLOT pos)
		| "mod" -> (PERT pos)
		| "obs" -> (OBS pos)
		| "def" -> (CONFIG pos)
		| "token" -> (TOKEN pos)
		| _ as s ->
		   raise (Syntax_Error ("Instruction \""^s^"\" not recognized",
					(Lexing.lexeme_start_p lexbuf,
					 Lexing.lexeme_end_p lexbuf)))
	       }
	 | '!' {let pos = position lexbuf in KAPPA_LNK pos}
	 | internal_state as s {let i = String.index s '~' in
				let r = String.sub s (i+1) (String.length s-i-1) in
				KAPPA_MRK r
			       }
	 | '?' {let pos = position lexbuf in (KAPPA_WLD pos)}
	 | '_' {let pos = position lexbuf in (KAPPA_SEMI pos)}
	 | blank  {token lexbuf}
	 | eof {reach_eof lexbuf; EOF}
	 | _ as c {
		    raise (Syntax_Error
			     ("invalid use of character "^ String.make 1 c,
			      (Lexing.lexeme_start_p lexbuf,
			       Lexing.lexeme_end_p lexbuf)))
		  }

and read_label acc char_list =
  parse
  | eof {String.concat "" (List.rev_map (fun x -> String.make 1 x) acc)}
  | '\\' eol {Lexing.new_line lexbuf ; read_label acc char_list lexbuf}
  | _ as c {if List.mem c char_list
	    then String.concat "" (List.rev_map (fun x -> String.make 1 x) acc)
	    else read_label (c::acc) char_list lexbuf}

and comment = parse
	    | eol {Lexing.new_line lexbuf ; NEWLINE}
	    | '\\' eol {Lexing.new_line lexbuf; token lexbuf}
	    | eof {EOF}
	    | _ {comment lexbuf}

and inline_comment = parse
		   | eol {Lexing.new_line lexbuf; inline_comment lexbuf}
		   | '*' '/' { () }
		   | '\"'
		       {ignore (read_label [] ['\"'] lexbuf);
			inline_comment lexbuf}
		   | '/' '*' {inline_comment lexbuf; inline_comment lexbuf}
		   | _ {inline_comment lexbuf}
{
  let compile logger fic =
    let d = open_in fic in
    Parameter.openInDescriptors := d::(!Parameter.openInDescriptors);
    let lexbuf = Lexing.from_channel d in
    lexbuf.lex_curr_p <- {lexbuf.lex_curr_p with pos_fname = fic} ;
    try
      Debug.tag logger ("Parsing "^fic^"...") ;
      KappaParser.start_rule token lexbuf ; Debug.tag logger "done" ; close_in d ;
      Parameter.openInDescriptors := List.tl (!Parameter.openInDescriptors)
    with
    | Syntax_Error (msg,pos) ->
       (close_in d ;
	Parameter.openInDescriptors := List.tl (!Parameter.openInDescriptors);
	let () = Pp.error Format.pp_print_string (msg,pos) in
	exit 1
       )
}
