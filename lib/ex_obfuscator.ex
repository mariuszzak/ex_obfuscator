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

defimpl ExObfuscator, for: [Map, List] do
  def call(input, nil) do
    call(input, :all)
  end

  def call(input, blacklisted_keys) when is_map(input), do: call(input, blacklisted_keys, %{})
  def call(input, blacklisted_keys) when is_list(input), do: call(input, blacklisted_keys, [])

  defp call(input, blacklisted_keys, final_type) do
    input
    |> obfuscate(blacklisted_keys)
    |> Enum.into(final_type)
  end

  defp obfuscate(enum, blacklisted_keys) do
    Enum.map(enum, fn element ->
      case element do
        {key, val} -> maybe_obfuscate(key, val, blacklisted_keys)
        val -> ExObfuscator.call(val, blacklisted_keys)
      end
    end)
  end

  defp maybe_obfuscate(key, val, blacklisted_keys) do
    cond do
      blacklisted_keys == :all ->
        {key, ExObfuscator.call(val)}

      is_map(key) ->
        {ExObfuscator.call(key, blacklisted_keys), ExObfuscator.call(val, blacklisted_keys)}

      key_is_blacklisted?(key, blacklisted_keys) ->
        {key, ExObfuscator.call(val)}

      is_map(val) ->
        {key, ExObfuscator.call(val, blacklisted_keys)}

      is_tuple(val) ->
        {key, ExObfuscator.call(val, blacklisted_keys)}

      {key, val} ->
        {key, val}
    end
  end

  defp to_strings(list) when is_list(list), do: Enum.map(list, &to_string/1)

  defp key_is_blacklisted?(key, blacklisted_keys) do
    # TODO: consider generating a list with all
    # blacklisted_keys with all variations of any "case" instead
    # of transforming each key into snake_case
    cond do
      to_string(key) in to_strings(blacklisted_keys) -> true
      to_string(to_snake_case(key)) in to_strings(blacklisted_keys) -> true
      true -> false
    end
  end

  defp to_snake_case(key) do
    key
    |> to_string()
    |> Recase.to_snake()
  end
end

defimpl ExObfuscator, for: Tuple do
  def call(val, blacklist) do
    val
    |> Tuple.to_list()
    |> Enum.map(fn element -> ExObfuscator.call(element, blacklist) end)
    |> List.to_tuple()
  end
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
  @struct_name :__ex_obf_struct__

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
