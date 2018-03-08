Application.put_env(:elixir, :ansi_enabled, true)
IEx.configure(
  inspect: [pretty: true, limit: :infinity],
  colors: [enabled: true],
  default_prompt: [
    "\e[G",    # ANSI CHA, move cursor to column 1
    :blue,
    "client \u2234", # prompt
    :reset
  ] |> IO.ANSI.format |> IO.chardata_to_string
)
