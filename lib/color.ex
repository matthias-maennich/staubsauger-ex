defmodule Color do
  def green(text), do: IO.ANSI.green() <> text <> IO.ANSI.reset()
  def red(text), do: IO.ANSI.red() <> text <> IO.ANSI.reset()
  def yellow(text), do: IO.ANSI.yellow() <> text <> IO.ANSI.reset()
end