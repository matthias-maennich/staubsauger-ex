defmodule Staubsauger.Application do
  use Application

  def start(_type, _args) do
    Supervisor.start_link([{Staubsauger, []}], strategy: :one_for_all)
  end
end