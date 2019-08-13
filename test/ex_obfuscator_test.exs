defmodule ExObfuscatorTest do
  use ExUnit.Case
  doctest ExObfuscator

  defmodule FooStruct do
    defstruct [:string, :integer, :atom, :map, :nested_map, :not_blacklisted]
  end

  alias ExObfuscatorTest.FooStruct

  test "obfuscates a map with blacklisted atom keys" do
    input = %{
      blacklisted_key: "Some value",
      regular_key: "Other value"
    }

    expected_output = %{
      blacklisted_key: "Som*******",
      regular_key: "Other value"
    }

    assert ExObfuscator.call(input, [:blacklisted_key]) == expected_output
  end

  test "obfuscates a map with blacklisted string keys" do
    input = %{
      "blacklisted_key" => "Some value",
      "regular_key" => "Other value"
    }

    expected_output = %{
      "blacklisted_key" => "Som*******",
      "regular_key" => "Other value"
    }

    assert ExObfuscator.call(input, ["blacklisted_key"]) == expected_output
  end

  test "obfuscates multiple keys in a map" do
    input = %{
      "blacklisted_key1" => "Some value",
      "blacklisted_key2" => "Some value",
      "regular_key" => "Other value"
    }

    expected_output = %{
      "blacklisted_key1" => "Som*******",
      "blacklisted_key2" => "Som*******",
      "regular_key" => "Other value"
    }

    assert ExObfuscator.call(input, ["blacklisted_key1", "blacklisted_key2"]) == expected_output
  end

  test "obfuscates mix of atom and string keys in a map" do
    input = %{
      "blacklisted_key1" => "Some value",
      :blacklisted_key2 => "Some value",
      "regular_key" => "Other value"
    }

    expected_output = %{
      "blacklisted_key1" => "Som*******",
      :blacklisted_key2 => "Som*******",
      "regular_key" => "Other value"
    }

    assert ExObfuscator.call(input, ["blacklisted_key1", :blacklisted_key2]) == expected_output
  end

  test "obfuscates also keys that are opposite type" do
    input = %{
      "blacklisted_key1" => "Some value",
      :blacklisted_key2 => "Some value",
      "regular_key" => "Other value"
    }

    expected_output = %{
      "blacklisted_key1" => "Som*******",
      :blacklisted_key2 => "Som*******",
      "regular_key" => "Other value"
    }

    assert ExObfuscator.call(input, [:blacklisted_key1, "blacklisted_key2"]) == expected_output
  end

  test "obfuscates short strings completely" do
    input = %{
      "short1" => "123456",
      "short2" => "12345",
      "short3" => "1234",
      "short4" => "12",
      "short5" => "1",
      "empty" => ""
    }

    expected_output = %{
      "short1" => "123***",
      "short2" => "***",
      "short3" => "***",
      "short4" => "***",
      "short5" => "***",
      "empty" => ""
    }

    blacklist = ~w(short1 short2 short3 short4 short5 empty)

    assert ExObfuscator.call(input, blacklist) ==
             expected_output
  end

  test "don't obfuscate nil vals" do
    input = %{
      "empty" => nil
    }

    expected_output = %{
      "empty" => nil
    }

    blacklist = ~w(empty)

    assert ExObfuscator.call(input, blacklist) == expected_output
  end

  test "obfuscates a string value" do
    assert ExObfuscator.call("FooBarBaz") == "Foo******"
  end

  test "obfuscates a very long string value"

  test "obfuscates a numeric value" do
    assert ExObfuscator.call(123) == "***"

    input = %{
      "numeric" => 123
    }

    expected_output = %{
      "numeric" => "***"
    }

    blacklist = ~w(numeric)

    assert ExObfuscator.call(input, blacklist) == expected_output
  end

  test "obfuscates a boolean value"

  test "obfuscates a struct" do
    input = %FooStruct{
      string: "FooFooFoo",
      integer: 123,
      atom: :foo_bar_baz,
      map: %{
        foo: "foofoofoo",
        bar: "barbarbar",
        baz: "bazbazbaz",
        nested: %{
          foo: "foofoofoo",
          bar: "barbarbar",
          baz: "bazbazbaz"
        }
      },
      nested_map: %{
        string: "FooFooFoo",
        not_blacklisted: "other value"
      },
      not_blacklisted: "other value"
    }

    expected_output = %FooStruct{
      string: "Foo******",
      integer: "***",
      atom: :foo_bar_baz,
      map: %{
        foo: "foo******",
        bar: "bar******",
        baz: "baz******",
        nested: %{
          foo: "foo******",
          bar: "bar******",
          baz: "baz******"
        }
      },
      nested_map: %{
        string: "Foo******",
        not_blacklisted: "other value"
      },
      not_blacklisted: "other value"
    }

    blacklist = ~w(string integer atom map)

    assert ExObfuscator.call(input, blacklist) == expected_output
  end

  test "obfuscates a tuple"

  test "obfuscates a nested map" do
    input = %{
      foo: %{
        bar: %{
          baz: "bazbazbaz"
        }
      },
      regular_key: "Other value"
    }

    expected_output = %{
      foo: %{
        bar: %{
          baz: "baz******"
        }
      },
      regular_key: "Other value"
    }

    assert ExObfuscator.call(input, [:baz]) == expected_output
  end

  test "obfuscates all key/vals in when a map is a value of blacklisted key" do
    input = %{
      blacklisted: %{
        foo: "foofoofoo",
        bar: "barbarbar",
        baz: "bazbazbaz",
        nested: %{
          foo: "foofoofoo",
          bar: "barbarbar",
          baz: "bazbazbaz"
        }
      },
      regular_key: "Other value"
    }

    expected_output = %{
      blacklisted: %{
        foo: "foo******",
        bar: "bar******",
        baz: "baz******",
        nested: %{
          foo: "foo******",
          bar: "bar******",
          baz: "baz******"
        }
      },
      regular_key: "Other value"
    }

    assert ExObfuscator.call(input, [:blacklisted]) == expected_output
  end

  test "obfuscates a nested map with a tuple"
  test "obfuscates a nested map with a tuple with a map"
  test "obfuscates a tuple with a map"
  test "obfuscates a tuple with a tuple"
  test "obfuscates a list"
  test "obfuscates a list of maps"
  test "obfuscates a list of tuples"
  test "obfuscates a list of structs"
  test "obfuscates a keyword list"
  test "obfuscates a keyword list with nested maps"
  test "obfuscates a very complex nested structure containing all possible types"
  test "obfuscates a camelCase keys even if blacklisted snake_case key"
  test "obfuscates a kebab-case keys even if blacklisted snake_case key"
  test "allows to completely drop a key"
  test "allows to force obfuscating the whole value of a specific key"
  test "allows to configure the visible string length"
  test "allows to configure the max length of obfuscated value"
  test "allows to configure the number of characters when the value will be obfuscated totally"
  test "allows to configure if nil values are supposed to stay nil or be treated as filled value"
  test "allows to configure global case sensitivity"
  test "allows to configure case sensitivity per key"
  test "allows to configure if numberic values are supposed to be obfuscated"
  test "allows to configure if camelCase/kebab-case keys are supposed to be obfuscated (globally)"
  test "allows to configure if camelCase/kebab-case keys are supposed to be obfuscated (per key)"
  test "allows to switch blacklist to whitelist"
  test "allows to combine blacklist and whitelist"
end
