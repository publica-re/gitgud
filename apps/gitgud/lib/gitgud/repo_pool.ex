defmodule GitGud.RepoPool do
  @moduledoc """
  Conveniences for working with a pool of repository processes.
  """
  use DynamicSupervisor

  alias GitRekt.GitAgent

  alias GitGud.Repo
  alias GitGud.RepoStorage
  alias GitGud.RepoRegistry

  @doc """
  Starts the pool as part of a supervision tree.
  """
  def start_link(opts \\ []) do
    opts = Keyword.put(opts, :name, __MODULE__)
    DynamicSupervisor.start_link(__MODULE__, [], opts)
  end

  @doc """
  Starts a `GitRekt.GitAgent` process for the given `repo`.
  """
  @spec start_agent(Repo.t, term) :: {:ok, pid} | {:error, term}
  def start_agent(repo, cache \\ nil) do
    via_registry = {:via, Registry, {RepoRegistry, "#{repo.owner.login}/#{repo.name}", cache}}
    agent_opts = [name: via_registry, idle_timeout: 900_000]
    agent_opts = cache && [{:cache, cache}|agent_opts] || agent_opts
    DynamicSupervisor.start_child(__MODULE__, %{
      id: GitAgent,
      start: {GitAgent, :start_link, [RepoStorage.workdir(repo), agent_opts]},
      restart: :temporary
    })
  end

  @doc """
  Retrieves an agent from the registry.
  """
  @spec lookup(Repo.t | Path.t) :: pid | nil
  def lookup(%Repo{} = repo), do: lookup(Path.join(repo.owner.login, repo.name))
  def lookup(path) do
    case Registry.lookup(GitGud.RepoRegistry, path) do
      [{agent, nil}] -> agent
      [{agent, cache}] -> {agent, cache}
      [] -> nil
    end
  end

  #
  # Callbacks
  #

  @impl true
  def init([]),  do: DynamicSupervisor.init(strategy: :one_for_one)
end
