functor ParserFn (Base : ParserBase) :>
        Parser where type ('a, 'b) result = ('a, 'b) Base.result =
struct
open Base
(* type 'a result = ({position : position, *)
(*                    error    : string} Set.t, *)
(*                   'a) Either.t *)
infix 0 |||
infix 1 --- |-- --|
infix 2 >>> --> ??? produce


(* fun depends m = (any --> m) handle Match => fail *)

fun map f p = (p --> return o f)
fun (p1 --- p2) = p1 --> (fn a => p2 --> return o pair a)
fun (p1 --| p2) = p1 --> (fn x => p2 --> (fn _ => return x))
fun (p1 |-- p2) = p1 --> (fn _ => p2 --> (fn x => return x))
fun p produce x = p |-- return x

(* TODO: foo *)
fun predicate pr p =
    p --> (fn x =>
              if pr x then
                return x
              else
                fail
          )
fun lookAhead p =
    getState --> (fn state =>
    p --> (fn x =>
      setState state |-- return x
    ))

fun notFollowedBy p =
    getState --> (fn s =>
    try p --> (fn _ => setState s |-- fail) ||| return ()
    )

fun eof c = (notFollowedBy any ??? "end of stream") c

fun token t =
    any --> (fn t' =>
      if t = t' then
        return t
      else
        fail
    )

fun (lexer >>> parser) c = parser $ lexer c

fun choice [p] = p
  | choice (p :: ps) = p ||| choice ps
  | choice _ = (any |-- fail) ??? "at least one parser in choice"
fun link ps = foldr (map op:: o op---) (return nil) ps
fun count 0 p = return nil
  | count n p = map op:: (p --- count (n - 1) p)
fun many p c = (map op:: $ try (p --- many p) ||| return nil) c
fun many1 p = map op:: (p --- many p)
fun maybe p = map SOME p ||| return NONE
fun between l r p = l |-- p --| r
fun followedBy p = lookAhead p produce ()
fun manyTill p stop = stop produce nil |||
                      map op:: (p --- manyTill p stop)
fun sepBy1 p sep = map op:: (p --- many (p --| sep))
fun sepBy p sep = sepBy1 p sep ||| return nil
fun endBy p e = many (p --| e)
fun endBy1 p e = many1 (p --| e)
fun sepEndBy p sep = sepBy p sep --| maybe sep
fun sepEndBy1 p sep = sepBy1 p sep --| maybe sep
fun chainr1 p oper =
    let
      fun scan c = (p --> rest) c
      and rest x = map op$ (oper --- scan) ||| return x
    in
      scan
    end
fun chainr p oper x = chainr1 p oper ||| return x
(* fun chainl  *)


structure Text =
struct
fun char c = try (token c) ??? ("'" ^ str c ^ "'")

(* I actually wrote this - refactor please *)
fun string s =
    let
      fun loop nil = return nil
        | loop (c :: cs) = map op:: (char c --- loop cs) ???
                           ("'" ^ str c ^ "' in \"" ^ s ^ "\"")
    in
      map implode $ loop (explode s)
    end

(* fun keywords ks = *)
(*     let *)
      
(*     in *)
      
(*     end *)
end

structure Parse =
struct
fun vector p show v =
    fst $ parse p show VectorSlice.getItem (VectorSlice.full v)
fun vectorFull p = vector (p --| eof)

fun run p show r s = fst $ parse p show r s
fun full p = run (p --| eof)

fun string p s = vector p (fn c => "'" ^ str c ^ "'") s
fun stringFull p s = vectorFull p (fn c => "'" ^ str c ^ "'") s

fun list p show l = fst $ parse p show List.getItem l
fun listFull p = list (p --| eof)

fun file p f = string p $ TextIO.readFile f
fun fileFull p = file (p --| eof)
end
end
