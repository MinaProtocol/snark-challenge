open Core
module Html = Html_concise

module Parameter_kind = struct
  type t = Batch_parameter | Input | Output
end

module Interface = struct
  module F = struct
    type 'a t =
      | Declare of Parameter_kind.t * string * Type.t * (Name.t -> 'a)
      | Choose_definitional_parameter :
          (Type.t, 'n) Vec.t list
          * (string, 'n) Vec.t
          * ((Name.t, 'n) Vec.t -> 'a)
          -> 'a t

    let map t ~f =
      match t with
      | Choose_definitional_parameter (xs, names, k) ->
          Choose_definitional_parameter (xs, names, fun x -> f (k x))
      | Declare (p, s, t, k) ->
          Declare (p, s, t, fun n -> f (k n))
  end

  include Free_monad.Make (F)

  let ( ! ) p s t = Free (Declare (p, s, t, return))

  let def names ts = Free (Choose_definitional_parameter (ts, names, return))

  module Spec = struct
    type ('a, 'n) spec =
      { definitional_parameters: (string, 'n) Vec.t * (Type.t, 'n) Vec.t list
      ; batch_parameters: (string * Type.t) list
      ; input: (string * Type.t) list
      ; output: (string * Type.t) list
      ; description: 'a }
    [@@deriving fields]

    let field = function
      | Parameter_kind.Batch_parameter ->
          Fields_of_spec.batch_parameters
      | Input ->
          Fields_of_spec.input
      | Output ->
          Fields_of_spec.output

    type 'a t = T : ('a, 'n) spec -> 'a t

    let update s pk ~f =
      let field = field pk in
      Field.fset field s (f (Field.get field s))

    let create ~name:_ m =
      cata
        (map m ~f:(fun description ->
             T
               { description
               ; definitional_parameters= ([], [])
               ; batch_parameters= []
               ; input= []
               ; output= [] } ))
        ~f:(function
          | Declare (pk, s, t, k) ->
              let (T spec) = k (Name.local s) in
              T (update spec pk ~f:(fun xs -> (s, t) :: xs))
          | Choose_definitional_parameter (choices, names, k) ->
              let (T spec) = k (Vec.map names ~f:(fun s -> Name.local s)) in
              T {spec with definitional_parameters= (names, choices)} )

    let render
        (T
          { description
          ; definitional_parameters
          ; batch_parameters
          ; input
          ; output }) =
      let open Html in
      let definitional_preamble =
        let names, choices = definitional_parameters in
        match choices with
        | [] ->
            []
        | _ ->
            [ span []
                ( text "The following problem is defined for any choice of ("
                  :: List.intersperse ~sep:(text ",")
                       (List.map (Vec.to_list names) ~f:(fun name ->
                            Name.render_declaration name ))
                @ [text ") in"] )
            ; ul []
                (List.map choices ~f:(fun choice ->
                     li []
                       (List.intersperse
                          (List.map (Vec.to_list choice) ~f:Type.render)
                          ~sep:(text ", ")) ))
            ; p
                "You can click on the types of any of the parameters, inputs, \
                 or outputs tosee how they will be represented in the files \
                 given to your program." ]
      in
      let params ?desc ~title xs =
        div [class_ "parameters"]
          ( [h2 [] [text title]]
          @ Option.to_list desc
          @ [ ul [class_ "value-list"]
                (List.map xs ~f:(fun (ident, ty) ->
                     li []
                       [ div []
                           [ span [class_ "identifier"] [text ident]
                           ; text ":"
                           ; span [class_ "type"] [Type.render ty] ]
                       ; div [class_ "representation"] [] ] )) ] )
      in
      let batch_parameters =
        params ~title:"Parameters"
          ~desc:
            (p
               "The parameters will be generated once and your submission \
                will be allowed to preprocess them in any way you like before \
                being invoked on multiple inputs.")
          batch_parameters
      in
      let input = params ~title:"Input" input in
      let output = params ~title:"Output" output in
      div [class_ "problem"]
        (definitional_preamble @ [batch_parameters; input; output; description])
  end
end

type t =
  { title: string
  ; interface: Html.t Interface.t
  ; reference_implementation_url: string }

let render {title; interface; reference_implementation_url} =
  let open Html in
  div []
    [ h1 [] [text title]
    ; Interface.Spec.(render (create ~name:title interface))
    ; div []
        [ h2 [] [text "Submission guidelines"]
        ; markdown
            {md|
Your submission will be run and evaluated as follows.

0. The submission-runner will randomly generate the parameters and save them to a file `PATH_TO_PARAMETERS`
1. Your binary `main` will be run with 

    ```bash
    ./main preprocess PATH_TO_PARAMETERS
    ```
    where `PATH_TO_PARAMETERS` will be replaced by the acutal path.

    Your binary can at this point, if you like, do some preprocessing of the parameters and
    save any state it would like to a file `./preprocessed`.

2. The submission runner will generate a random sequence of inputs, saved to a file
   `PATH_TO_INPUTS`.

3. Your binary will be invoked with

    ```bash
    ./main compute PATH_TO_INPUTS
    ```

    and its runtime will be recorded. It can, if it likes, read
    the file "./preprocessed" in order to help it solve the problem.|md}
        ]
    ; hr []
    ; a [href reference_implementation_url] [text "Reference implementation"]
    ]
