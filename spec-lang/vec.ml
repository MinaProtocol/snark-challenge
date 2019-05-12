type z = Zero

type 'a s = S of 'a

type ('a, 'n) t = [] : ('a, z) t | ( :: ) : 'a * ('a, 'n) t -> ('a, 'n s) t

let rec map : type a n b. (a, n) t -> f:(a -> b) -> (b, n) t =
 fun t ~f -> match t with [] -> [] | x :: xs -> f x :: map xs ~f

let rec to_list : type a n. (a, n) t -> a list = function
  | [] ->
      []
  | x :: xs ->
      x :: to_list xs
