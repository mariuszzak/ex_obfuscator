defmodule ExObfuscator do
  defprotocol Obfuscate do
    def call(value)
  end

  defimpl Obfuscate, for: BitString do
    def call(val) do
      str_length = String.length(val)

      cond do
        str_length > 5 -> String.slice(val, 0..2) <> String.duplicate("*", str_length - 3)
        str_length == 0 -> ""
        str_length -> "***"
      end
    end
  end

  defimpl Obfuscate, for: Integer do
    def call(_val), do: "***"
  end

  defimpl Obfuscate, for: Atom do
    def call(nil), do: nil
  end

  def call(input, blacklisted_keys \\ nil)
  def call(input, nil), do: Obfuscate.call(input)

  def call(input, blacklisted_keys) do
    input
    |> Enum.map(fn {key, val} -> maybe_obfuscate(key, val, blacklisted_keys) end)
    |> Enum.into(%{})
  end

  defp maybe_obfuscate(key, val, blacklisted_keys) do
    if to_string(key) in to_strings(blacklisted_keys) do
      {key, Obfuscate.call(val)}
    else
      {key, val}
    end
  end

  defp to_strings(list) when is_list(list), do: Enum.map(list, &to_string/1)
end
