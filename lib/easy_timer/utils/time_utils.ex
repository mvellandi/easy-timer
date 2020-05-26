defmodule EasyTimer.TimeUtils do
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

  def seconds_to_clock(seconds, delimeter) do
    {h, m, s, _ms} =
      seconds
      |> Timex.Duration.from_seconds()
      |> Timex.Duration.to_clock()

    time =
      %{hours: h, minutes: m, seconds: s}
      |> Enum.map(fn {k, v} ->
        case k do
          :hours ->
            cond do
              v == 0 -> {k, ""}
              v < 10 -> {k, "0#{v}#{delimeter}"}
              true -> {k, "#{v}#{delimeter}"}
            end

          :minutes ->
            cond do
              v == 0 -> {k, "00#{delimeter}"}
              v < 10 -> {k, "0#{v}#{delimeter}"}
              true -> {k, "#{v}#{delimeter}"}
            end

          :seconds ->
            cond do
              v == 0 -> {k, "00"}
              v < 10 -> {k, "0#{v}"}
              true -> {k, v}
            end
        end
      end)
      |> Enum.into(%{})

    time
  end
end
