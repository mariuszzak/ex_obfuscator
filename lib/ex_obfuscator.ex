defprotocol ExObfuscator do
  @fallback_to_any true
  def call(value, blacklist \\ nil)
end

defimpl ExObfuscator, for: BitString do
  def call(val, _blacklist) do
    str_length = String.length(val)

    cond do
      str_length > 5 -> obfuscate(val, str_length)
      str_length == 0 -> ""
      str_length -> "***"
    end
  end

  defp obfuscate(val, str_length),
    do: String.slice(val, 0..2) <> String.duplicate("*", str_length - 3)
end

defimpl ExObfuscator, for: List do
  def call(val, _blacklist), do: val
end

defimpl ExObfuscator, for: Map do
  def call(input, nil) do
    call(input, :all)
  end

  def call(input, blacklisted_keys) do
    input
    |> Enum.map(fn {key, val} -> maybe_obfuscate(key, val, blacklisted_keys) end)
    |> Enum.into(%{})
  end

  defp maybe_obfuscate(key, val, blacklisted_keys) do
    cond do
      blacklisted_keys == :all ->
        {key, ExObfuscator.call(val)}

      to_string(key) in to_strings(blacklisted_keys) ->
        {key, ExObfuscator.call(val)}

      is_map(val) ->
        {key, ExObfuscator.call(val, blacklisted_keys)}

      {key, val} ->
        {key, val}
    end
  end

  defp to_strings(list) when is_list(list), do: Enum.map(list, &to_string/1)
end

defimpl ExObfuscator, for: Tuple do
  def call(val, _blacklist), do: val
end

defimpl ExObfuscator, for: Atom do
  def call(nil, _blacklist), do: nil
  def call(val, _blacklist) when is_boolean(val), do: "***"
  def call(val, _blacklist), do: val
end

defimpl ExObfuscator, for: [Integer, Float] do
  def call(_val, _blacklist), do: "***"
end

defimpl ExObfuscator, for: [Function, PID, Port, Reference] do
  def call(val, _blacklist), do: val
end

defimpl ExObfuscator, for: Any do
  @struct_name :__struct_name__

  def call(%{__struct__: struct_key} = struct, blacklist) do
    struct
    |> Map.put(@struct_name, struct_key)
    |> Map.from_struct()
    |> ExObfuscator.call(blacklist)
    |> revert_struct()
  end

  defp revert_struct(%{@struct_name => struct_name} = struct_attrs),
    do: struct(struct_name, Map.delete(struct_attrs, @struct_name))
end
