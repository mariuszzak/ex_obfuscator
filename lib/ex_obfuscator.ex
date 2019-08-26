defprotocol ExObfuscator do
  @fallback_to_any true
  def call(value, blacklist \\ nil, opts \\ [])
end

defimpl ExObfuscator, for: BitString do
  @num_of_visible_chars 3
  @max_string_length 20

  def call(val, _blacklist, opts \\ []) do
    str_length = String.length(val)

    cond do
      str_length > 5 -> obfuscate(val, str_length, opts)
      str_length == 0 -> ""
      str_length -> "***"
    end
  end

  defp obfuscate(_val, str_length, obfuscate_entire_value: true) do
    "***" <> stars(str_length) <> maybe_dots(str_length)
  end

  defp obfuscate(val, str_length, _opts) do
    visible_chars(val) <> stars(str_length) <> maybe_dots(str_length)
  end

  defp visible_chars(val), do: String.slice(val, 0..(@num_of_visible_chars - 1))
  defp stars(str_length), do: String.duplicate("*", min(str_length, @max_string_length) - 3)
  defp maybe_dots(str_length) when str_length > @max_string_length, do: "..."
  defp maybe_dots(_str_length), do: ""
end

defimpl ExObfuscator, for: [Map, List] do
  def call(input, blacklisted_keys, opts \\ [])

  def call(input, nil, _opts) do
    call(input, :all)
  end

  def call(input, blacklisted_keys, opts) when is_map(input),
    do: call(input, blacklisted_keys, opts, %{})

  def call(input, blacklisted_keys, opts) when is_list(input) do
    input
    |> call(blacklisted_keys, opts, [])
    |> Enum.reverse()
  end

  defp call(input, blacklisted_keys, _opts, final_type) do
    input
    |> obfuscate(blacklisted_keys)
    |> Enum.into(final_type)
  end

  defp obfuscate(enum, blacklisted_keys) do
    Enum.reduce(enum, [], fn element, acc ->
      case element do
        {key, val} ->
          key
          |> maybe_obfuscate(val, blacklisted_keys)
          |> maybe_append_value(acc)

        val ->
          [ExObfuscator.call(val, blacklisted_keys) | acc]
      end
    end)
  end

  defp maybe_obfuscate(key, val, blacklisted_keys) do
    cond do
      blacklisted_keys == :all ->
        {key, ExObfuscator.call(val)}

      is_map(key) ->
        {ExObfuscator.call(key, blacklisted_keys), ExObfuscator.call(val, blacklisted_keys)}

      should_drop_key?(key, blacklisted_keys) ->
        nil

      should_obfuscate_entire_value?(key, blacklisted_keys) ->
        {key, ExObfuscator.call(val, [], obfuscate_entire_value: true)}

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

  defp maybe_append_value(nil, acc), do: acc
  defp maybe_append_value(val, acc), do: [val | acc]

  defp to_strings(list) when is_list(list), do: Enum.map(list, &to_string/1)

  defp should_drop_key?(key, blacklisted_keys),
    do: Keyword.keyword?(blacklisted_keys) && Keyword.get(blacklisted_keys, key) == :drop

  defp should_obfuscate_entire_value?(key, blacklisted_keys) do
    Keyword.keyword?(blacklisted_keys) &&
      Keyword.get(blacklisted_keys, key) == :obfuscate_entire_value
  end

  defp key_is_blacklisted?(key, blacklisted_keys) do
    # TODO: consider generating a list with all
    # blacklisted_keys with all variations of any "case" instead
    # of transforming each key into snake_case
    cond do
      Keyword.keyword?(blacklisted_keys) ->
        key_is_blacklisted?(key, Keyword.keys(blacklisted_keys))

      to_string(key) in to_strings(blacklisted_keys) ->
        true

      to_string(to_snake_case(key)) in to_strings(blacklisted_keys) ->
        true

      true ->
        false
    end
  end

  defp to_snake_case(key) do
    key
    |> to_string()
    |> Recase.to_snake()
  end
end

defimpl ExObfuscator, for: Tuple do
  def call(val, blacklist, _opts) do
    val
    |> Tuple.to_list()
    |> Enum.map(fn element -> ExObfuscator.call(element, blacklist) end)
    |> List.to_tuple()
  end
end

defimpl ExObfuscator, for: Atom do
  def call(nil, _blacklist, _opts), do: nil
  def call(val, _blacklist, _opts) when is_boolean(val), do: "***"
  def call(val, _blacklist, _opts), do: val
end

defimpl ExObfuscator, for: [Integer, Float] do
  def call(_val, _blacklist, _opts), do: "***"
end

defimpl ExObfuscator, for: [Function, PID, Port, Reference] do
  def call(val, _blacklist, _opts), do: val
end

defimpl ExObfuscator, for: Any do
  @struct_name :__ex_obf_struct__

  def call(%{__struct__: struct_key} = struct, blacklist, _opts) do
    struct
    |> Map.put(@struct_name, struct_key)
    |> Map.from_struct()
    |> ExObfuscator.call(blacklist)
    |> revert_struct()
  end

  defp revert_struct(%{@struct_name => struct_name} = struct_attrs),
    do: struct(struct_name, Map.delete(struct_attrs, @struct_name))
end
