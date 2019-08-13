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

  defp obfuscate_value(val) do
    String.slice(val, 0..2) <> String.duplicate("*", String.length(val) - 3)
  end

  defp to_strings(list) when is_list(list), do: Enum.map(list, &to_string/1)
end
