open Core
open Util

module Reward = struct
  type t = Dollars of int | Swag_bag

  let to_string = function
    | Swag_bag ->
        "Swag bag including SNARK challenge poster."
    | Dollars d ->
        sprintf "$%s" (Int.to_string_hum ~delimiter:',' d)
end

module Condition = struct
  type t = Improve_speed_by of int
end

module Participant_set = struct
  type t =
    | All
    | First_n of int
    | First_to of Condition.t
    | Best_performance_at_end

  let to_string = function
    | All ->
        "All submissions"
    | First_n n ->
        sprintf "First %d submissions" n
    | Best_performance_at_end ->
        "Fastest at end of competition"
    | First_to (Improve_speed_by n) ->
        sprintf "First submission to increase speed by %dx" n
end

type t = (Participant_set.t * Reward.t) list

let render xs =
  let open Html in
  ul []
    (List.map xs ~f:(fun (p, r) ->
         li []
           [ ksprintf Html.markdown "**%s**: %s"
               (Participant_set.to_string p)
               (Reward.to_string r) ] ))

let stage1 amount : t = [(First_n 25, Dollars amount); (All, Swag_bag)]
