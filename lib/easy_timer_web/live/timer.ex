defmodule EasyTimerWeb.Timer do
  use Phoenix.LiveView
  alias Phoenix.PubSub

  @impl true
  def mount(%{"slug" => slug} = _params, _session, socket) do
    IO.inspect(slug)

    if connected?(socket) do
      key = "scenario:" <> slug
      PubSub.subscribe(EasyTimer.PubSub, key)
    end

    IO.puts("mount end")

    {:ok, assign(socket, slug: slug, seconds: nil, counter: 0)}
  end

  @imp true
  def handle_event("start", _params, %{assigns: %{slug: slug}} = socket) do
    EasyTimer.start(slug)
    {:noreply, socket}
  end

  @impl true
  def handle_info({"tick", phase}, socket) do
    IO.puts("tick on client")
    # IO.puts(phase)
    {:noreply, assign(socket, :seconds, phase.calc_remaining_seconds)}
  end

  # def handle_info(message, socket) do
  #   IO.inspect(message)
  #   {:noreply, socket}
  # end
end
