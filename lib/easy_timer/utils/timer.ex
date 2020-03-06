defmodule EasyTimer.Timer do
  @moduledoc """
  Functions for managing time
  """
  def length_of_second do
    case(Mix.env()) do
      :test -> 1
      _ -> 1000
    end
  end

  def calc_seconds(hours, minutes, seconds) do
    hours * 3600 + minutes * 60 + seconds
  end

  def time_less_or_equal_24(time), do: time <= 24
  def time_greater_24(time), do: time > 24
  def time_greater_or_equal_0(time), do: time >= 0
  def time_greater_0(time), do: time > 0
  def time_less_60(time), do: time < 60
  def time_greater_or_equal_60(time), do: time >= 60

  def send_after_second(pid, message, opts \\ []) do
    Process.send_after(pid, message, length_of_second(), opts)
  end
end
