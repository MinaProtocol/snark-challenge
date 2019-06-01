open Core
open Util

module Reward = struct
  type t = Dollars of int | Swag_bag

  let to_string = function
    | Swag_bag ->
        "Swag bag including SNARK challenge T-shirt."
    | Dollars d ->
        sprintf "$%s" (Int.to_string_hum ~delimiter:',' d)
end

module Condition = struct
  type t = Improve_speed_by of int
end

module Device = struct
  type t = Cpu | Cpu_and_gpu | Mobile
end

module Participant_set = struct
  type t =
    | All
    | First_n of int
    | First_to of Condition.t
    | Best_performance_at_end of Device.t
    | Highest_quality

  let to_string = function
    | All ->
        "All submissions"
    | Highest_quality ->
        "Highest quality at the end of the competition"
    | First_n n ->
        sprintf "First %d submissions" n
    | Best_performance_at_end device ->
        let s =
          match device with
          | Mobile ->
              "Android or iPhone"
          | Cpu ->
              "Benchark machine, CPU only"
          | Cpu_and_gpu ->
              "Benchark machine, CPU and GPU"
        in
        sprintf "%s: Fastest at end of competition" s
    | First_to (Improve_speed_by n) ->
        sprintf "First submission to increase speed by %dx" n
end

type t = (Participant_set.t * Reward.t) list

let dollar_amount (t : t) =
  List.sum
    (module Int)
    t
    ~f:(fun (_, d) -> match d with Reward.Swag_bag -> 0 | Dollars d -> d)

let render xs =
  let open Html in
  ul []
    (List.map xs ~f:(fun (p, r) ->
         li []
           [ ksprintf Html.markdown "**%s**: %s"
               (Participant_set.to_string p)
               (Reward.to_string r) ] ))

let stage1 amount : t = [(First_n 25, Dollars amount); (All, Swag_bag)]
