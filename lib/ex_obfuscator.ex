defmodule ExObfuscator do
  def call(input_map, blacklisted_keys) do
    input_map
    |> Enum.map(fn {key, val} -> maybe_obfuscate(key, val, blacklisted_keys) end)
    |> Enum.into(%{})
  end

  defp maybe_obfuscate(key, val, blacklisted_keys) do
    if to_string(key) in to_strings(blacklisted_keys) do
      {key, obfuscate_value(val)}
    else
      {key, val}
    end
  end

  defp obfuscate_value(val) when is_nil(val), do: nil

  defp obfuscate_value(val) do
    str_length = String.length(val)

    cond do
      str_length > 5 -> String.slice(val, 0..2) <> String.duplicate("*", str_length - 3)
      str_length == 0 -> ""
      str_length -> "***"
    end
  end

  defp to_strings(list) when is_list(list), do: Enum.map(list, &to_string/1)
end
