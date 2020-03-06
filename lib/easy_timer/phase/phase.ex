defmodule EasyTimer.Phase do
  alias EasyTimer.{Phase, Timer}

  defstruct id: nil,
            name: nil,
            duration_hours: nil,
            duration_minutes: nil,
            duration_seconds: nil,
            calc_remaining_seconds: nil,
            start_sound: false,
            start_sound_data: nil,
            warning_hour: nil,
            warning_minute: nil,
            warning_second: nil,
            calc_warning_second: nil,
            warning_sound: false,
            warning_sound_data: nil,
            end_sound: false,
            end_sound_data: nil

  @max_phase_length_seconds 86_400
  @min_phase_length_seconds 3

  def create(scenario_type, data) do
    with :ok <- validate_keys(data, scenario_type),
         {:ok, updated_data} <- validate_data(data, scenario_type) do
      {:ok, struct(Phase, updated_data)}
    else
      errors ->
        e = %{
          type: "Phase Creation Error",
          phase: "#{data.id}",
          message: "We've found one or more errors when trying to create a Phase.",
          errors: Enum.reverse(errors)
        }

        {:error, e}
    end
  end

  def validate_keys(data, scenario_type) do
    data_keys = Map.keys(data)
    valid_keys = valid_phase_keys(scenario_type)

    case Enum.reject(data_keys, &(&1 in valid_keys)) do
      [] ->
        :ok

      invalid_keys ->
        [
          %{
            type: "Invalid Keys/Headers",
            phase: "#{data.id}",
            message: "Valid keys/headers include: #{valid_keys |> Enum.join(", ")}",
            errors: "Keys: #{invalid_keys |> Enum.join(", ")}"
          }
        ]
    end
  end

  def valid_phase_keys(scenario_type) do
    case scenario_type do
      :quick ->
        [:duration_hours, :duration_minutes, :duration_seconds, :id]

      :custom ->
        Map.from_struct(%Phase{})
        |> Map.drop([:calc_remaining_seconds, :calc_warning_second])
        |> Map.keys()
    end
  end

  def validate_data(data, scenario_type) do
    result =
      %{errors: [], data: data}
      |> validate_name(scenario_type)
      |> validate_hours(:duration_hours)
      |> validate_minutes_seconds(:duration_minutes)
      |> validate_minutes_seconds(:duration_seconds)
      |> validate_phase_duration()

    # |> validate_boolean(:start_sound)
    # |> validate_sound_data(:start_sound_data)
    # |> validate_hours(:warning_hour)
    # |> validate_minutes_seconds(:warning_minute)
    # |> validate_minutes_seconds(:warning_second)
    # |> validate_phase_warning()
    # |> validate_boolean(:warning_sound)
    # |> validate_sound_data(:warning_sound_data)
    # |> validate_boolean(:end_sound)
    # |> validate_sound_data(:end_sound_data)

    case result do
      %{errors: [], data: updated_data} -> {:ok, updated_data}
      %{errors: errors} -> errors
    end
  end

  def validate_name(%{errors: _errors, data: _data} = result, scenario_type) do
    case scenario_type do
      :quick ->
        result

      :custom ->
        # if name !== valid do
        #   result
        # else
        #   e = prepare_data_error(%{key: :name, value: _name, id: data.id, message: "The name field..."})
        #   %{result | errors: [e | errors]}
        # end
        result
    end
  end

  def validate_hours(%{errors: errors, data: data} = result, key) do
    with {:ok, hours} <- convert_value_to_integer(data[key]) do
      if Timer.time_less_or_equal_24(hours) and Timer.time_greater_or_equal_0(hours) do
        %{result | data: Map.put(data, key, hours)}
      else
        e =
          prepare_data_error(%{
            key: key,
            value: hours,
            phase: data.id,
            message:
              "Please provide a #{key} value between 0 and #{
                div(@max_phase_length_seconds, 3_600)
              } hours."
          })

        %{result | errors: [e | errors]}
      end
    else
      {:error, string} ->
        e =
          prepare_data_error(%{
            key: key,
            value: string,
            phase: data.id,
            message: "Please provide a whole number for #{key}."
          })

        %{result | errors: [e | errors]}
    end
  end

  def validate_minutes_seconds(%{errors: errors, data: data} = result, key) do
    with {:ok, time} <- convert_value_to_integer(data[key]) do
      if Timer.time_less_60(time) and Timer.time_greater_or_equal_0(time) do
        %{result | data: Map.put(data, key, time)}
      else
        e =
          prepare_data_error(%{
            key: key,
            value: time,
            phase: data.id,
            message: "Please provide a #{key} value between 0 and 59."
          })

        %{result | errors: [e | errors]}
      end
    else
      {:error, string} ->
        e =
          prepare_data_error(%{
            key: key,
            value: string,
            phase: data.id,
            message: "Please provide a whole number for #{key}."
          })

        %{result | errors: [e | errors]}
    end
  end

  def validate_phase_duration(%{errors: errors, data: data} = result) do
    time =
      [hours, mins, secs] = [data.duration_hours, data.duration_minutes, data.duration_seconds]

    if Enum.all?(time, &is_integer(&1)) do
      phase_duration = Timer.calc_seconds(hours, mins, secs)

      if phase_duration <= @max_phase_length_seconds and
           phase_duration >= @min_phase_length_seconds do
        %{result | data: Map.put(data, :calc_remaining_seconds, phase_duration)}
      else
        e =
          prepare_data_error(%{
            key: "Total Phase Duration",
            value: "hours: #{hours}, minutes: #{mins}, seconds: #{secs}",
            phase: data.id,
            message:
              "Provide a total duration of at least #{@min_phase_length_seconds} seconds, and less than or equal to #{
                div(@max_phase_length_seconds, 3_600)
              } hours."
          })

        %{result | errors: [e | errors]}
      end
    else
      e =
        prepare_data_error(%{
          key: "Total Phase Duration",
          value: "hours: '#{hours}', minutes: '#{mins}', seconds: '#{secs}'",
          phase: data.id,
          message:
            "Provide some valid whole numbers for duration_hours, duration_minutes, and duration_seconds."
        })

      %{result | errors: [e | errors]}
    end
  end

  def convert_value_to_integer(value) do
    try do
      cond do
        is_binary(value) -> String.to_integer(value)
        is_integer(value) -> value
        true -> raise(ArgumentError, "")
      end
    rescue
      ArgumentError -> {:error, inspect(value)}
    else
      integer -> {:ok, integer}
    end
  end

  def convert_value_to_boolean(value) do
    bool =
      if is_binary(value) do
        value |> String.downcase() |> String.to_atom()
      else
        value
      end

    if is_boolean(bool), do: {:ok, bool}, else: {:error, value}
  end

  def prepare_data_error(%{key: key, value: value, phase: id, message: message}) do
    %{
      type: "Invalid #{key} Value",
      phase: "#{id}",
      message: message,
      errors: "#{key}: #{value}"
    }
  end
end
