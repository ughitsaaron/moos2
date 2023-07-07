defmodule Moos2.Error do
  def error(0), do: System.halt("Invalid input URL")
  def error(1), do: System.halt("Error during authentication")
end
