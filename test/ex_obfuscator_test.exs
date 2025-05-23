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
    assert ExObfuscator.call("FooBarBaz", [:foo]) == "Foo******"
  end

  test "obfuscates and shortens a string having more than 20 chars" do
    assert ExObfuscator.call("1234567890") == "123*******"
    assert ExObfuscator.call("1234567890" <> "1234567890") == "123*****************"

    shortened_value = "123*****************..."
    assert ExObfuscator.call("1234567890" <> "1234567890" <> "1") == shortened_value
    assert ExObfuscator.call("1234567890" <> "1234567890" <> "12") == shortened_value
    assert ExObfuscator.call("1234567890" <> "1234567890" <> "123") == shortened_value
    assert ExObfuscator.call("123" <> String.duplicate("a", 100_000)) == shortened_value
  end

  test "obfuscates a numeric value" do
    assert ExObfuscator.call(123) == "***"

    input = %{
      "integer" => 123,
      "float" => 1.23
    }

    expected_output = %{
      "integer" => "***",
      "float" => "***"
    }

    blacklist = ~w(integer float)

    assert ExObfuscator.call(input, blacklist) == expected_output
  end

  test "obfuscates a boolean value" do
    assert ExObfuscator.call(true) == "***"
    assert ExObfuscator.call(false) == "***"
    assert ExObfuscator.call(%{blacklisted: false}) == %{blacklisted: "***"}
  end

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

  test "obfuscates a tuple" do
    input = {:foo, :bar, :baz}
    expected_output = {:foo, :bar, :baz}
    assert ExObfuscator.call(input) == expected_output
  end

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

  test "obfuscates a nested map with a tuple" do
    input = {%{blacklisted: "foofoofoo", not_blacklisted: "barbarbar"}}
    expected_output = {%{blacklisted: "foo******", not_blacklisted: "barbarbar"}}
    assert ExObfuscator.call(input, [:blacklisted]) == expected_output

    input =
      {%{blacklisted: "foofoofoo", not_blacklisted: "barbarbar"},
       %{blacklisted: "foofoofoo", not_blacklisted: "barbarbar"}}

    expected_output =
      {%{blacklisted: "foo******", not_blacklisted: "barbarbar"},
       %{blacklisted: "foo******", not_blacklisted: "barbarbar"}}

    assert ExObfuscator.call(input, [:blacklisted]) == expected_output

    input =
      {%{blacklisted: "foofoofoo", not_blacklisted: "barbarbar"},
       %{blacklisted: "foofoofoo", not_blacklisted: "barbarbar"},
       %{blacklisted: "foofoofoo", not_blacklisted: "barbarbar"},
       %{blacklisted: "foofoofoo", not_blacklisted: "barbarbar"},
       %{blacklisted: "foofoofoo", not_blacklisted: "barbarbar"},
       %{blacklisted: "foofoofoo", not_blacklisted: "barbarbar"}}

    expected_output =
      {%{blacklisted: "foo******", not_blacklisted: "barbarbar"},
       %{blacklisted: "foo******", not_blacklisted: "barbarbar"},
       %{blacklisted: "foo******", not_blacklisted: "barbarbar"},
       %{blacklisted: "foo******", not_blacklisted: "barbarbar"},
       %{blacklisted: "foo******", not_blacklisted: "barbarbar"},
       %{blacklisted: "foo******", not_blacklisted: "barbarbar"}}

    assert ExObfuscator.call(input, [:blacklisted]) == expected_output
  end

  test "obfuscates a nested map with a tuple with a map" do
    input = %{
      nested:
        {%{blacklisted: "foofoofoo", not_blacklisted: "barbarbar"},
         %{blacklisted: "foofoofoo", not_blacklisted: "barbarbar"}}
    }

    expected_output = %{
      nested:
        {%{blacklisted: "foo******", not_blacklisted: "barbarbar"},
         %{blacklisted: "foo******", not_blacklisted: "barbarbar"}}
    }

    assert ExObfuscator.call(input, [:blacklisted]) == expected_output
  end

  test "obfuscates a map with map as key" do
    input = %{
      %{blacklisted: "foofoofoo", not_blacklisted: "barbarbar"} => %{
        blacklisted: "foofoofoo",
        not_blacklisted: "barbarbar"
      },
      %{blacklisted: "foofoofoo", not_blacklisted: "barbarbar2"} => %{
        blacklisted: "foofoofoo",
        not_blacklisted: "barbarbar2"
      }
    }

    expected_output = %{
      %{blacklisted: "foo******", not_blacklisted: "barbarbar"} => %{
        blacklisted: "foo******",
        not_blacklisted: "barbarbar"
      },
      %{blacklisted: "foo******", not_blacklisted: "barbarbar2"} => %{
        blacklisted: "foo******",
        not_blacklisted: "barbarbar2"
      }
    }

    assert ExObfuscator.call(input, [:blacklisted]) == expected_output
  end

  test "obfuscates a tuple with a map" do
    input =
      {%{blacklisted: "foofoofoo", not_blacklisted: "barbarbar"},
       %{blacklisted: "foofoofoo", not_blacklisted: "barbarbar"}}

    expected_output =
      {%{not_blacklisted: "barbarbar", blacklisted: "foo******"},
       %{not_blacklisted: "barbarbar", blacklisted: "foo******"}}

    assert ExObfuscator.call(input, [:blacklisted]) == expected_output
  end

  test "obfuscates a tuple with a tuple" do
    input =
      {{%{blacklisted: "foofoofoo", not_blacklisted: "barbarbar"},
        %{blacklisted: "foofoofoo", not_blacklisted: "barbarbar"}}}

    expected_output =
      {{%{not_blacklisted: "barbarbar", blacklisted: "foo******"},
        %{not_blacklisted: "barbarbar", blacklisted: "foo******"}}}

    assert ExObfuscator.call(input, [:blacklisted]) == expected_output

    input = {{"foofoofoo", "barbarbar"}}

    expected_output = {{"foo******", "bar******"}}

    assert ExObfuscator.call(input, [:blacklisted]) == expected_output
  end

  test "obfuscates a list" do
    input = ["foofoofoo", "barbarbar", "bazbazbaz"]
    expected_output = ["foo******", "bar******", "baz******"]
    assert ExObfuscator.call(input) == expected_output
  end

  test "obfuscates a list of maps" do
    input = [
      %{blacklisted: "foofoofoo", not_blacklisted: "barbarbar"},
      %{blacklisted: "foofoofoo", not_blacklisted: "barbarbar"}
    ]

    expected_output = [
      %{blacklisted: "foo******", not_blacklisted: "barbarbar"},
      %{blacklisted: "foo******", not_blacklisted: "barbarbar"}
    ]

    assert ExObfuscator.call(input, [:blacklisted]) == expected_output
  end

  test "obfuscates a list of tuples" do
    input = [
      {%{blacklisted: "foofoofoo", not_blacklisted: "barbarbar"},
       %{blacklisted: "foofoofoo", not_blacklisted: "barbarbar"}},
      {%{blacklisted: "foofoofoo", not_blacklisted: "barbarbar"},
       %{blacklisted: "foofoofoo", not_blacklisted: "barbarbar"}}
    ]

    expected_output = [
      {%{blacklisted: "foo******", not_blacklisted: "barbarbar"},
       %{blacklisted: "foo******", not_blacklisted: "barbarbar"}},
      {%{blacklisted: "foo******", not_blacklisted: "barbarbar"},
       %{blacklisted: "foo******", not_blacklisted: "barbarbar"}}
    ]

    assert ExObfuscator.call(input, [:blacklisted]) == expected_output

    input = [
      {%{blacklisted: "foofoofoo", not_blacklisted: "barbarbar"},
       %{blacklisted: "foofoofoo", not_blacklisted: "barbarbar"},
       %{blacklisted: "foofoofoo", not_blacklisted: "barbarbar"}},
      {%{blacklisted: "foofoofoo", not_blacklisted: "barbarbar"},
       %{blacklisted: "foofoofoo", not_blacklisted: "barbarbar"},
       %{blacklisted: "foofoofoo", not_blacklisted: "barbarbar"}}
    ]

    expected_output = [
      {%{blacklisted: "foo******", not_blacklisted: "barbarbar"},
       %{blacklisted: "foo******", not_blacklisted: "barbarbar"},
       %{blacklisted: "foo******", not_blacklisted: "barbarbar"}},
      {%{blacklisted: "foo******", not_blacklisted: "barbarbar"},
       %{blacklisted: "foo******", not_blacklisted: "barbarbar"},
       %{blacklisted: "foo******", not_blacklisted: "barbarbar"}}
    ]

    assert ExObfuscator.call(input, [:blacklisted]) == expected_output
  end

  test "obfuscates a list of structs" do
    struct = %FooStruct{
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

    input = [struct, struct]

    expected_output = [
      %FooStruct{
        atom: :foo_bar_baz,
        not_blacklisted: "other value",
        integer: "***",
        map: %{
          bar: "bar******",
          baz: "baz******",
          foo: "foo******",
          nested: %{bar: "bar******", baz: "baz******", foo: "foo******"}
        },
        nested_map: %{not_blacklisted: "other value", string: "Foo******"},
        string: "Foo******"
      },
      %FooStruct{
        atom: :foo_bar_baz,
        not_blacklisted: "other value",
        integer: "***",
        map: %{
          bar: "bar******",
          baz: "baz******",
          foo: "foo******",
          nested: %{bar: "bar******", baz: "baz******", foo: "foo******"}
        },
        nested_map: %{not_blacklisted: "other value", string: "Foo******"},
        string: "Foo******"
      }
    ]

    assert ExObfuscator.call(input, ~w(string integer atom map)) == expected_output
  end

  test "obfuscates a keyword list" do
    input = [blacklisted: "foofoofoo", not_blacklisted: "barbarbar"]
    expected_output = [blacklisted: "foo******", not_blacklisted: "barbarbar"]
    assert ExObfuscator.call(input, [:blacklisted]) == expected_output
  end

  test "obfuscates all values when a list is a value of blacklisted key in a map" do
    input = %{
      blacklisted: ["foofoofoo", "barbarbar", "bazbazbaz"],
      regular_key: "Other value"
    }

    expected_output = %{
      blacklisted: ["foo******", "bar******", "baz******"],
      regular_key: "Other value"
    }

    assert ExObfuscator.call(input, [:blacklisted]) == expected_output
  end

  test "obfuscates a keyword list with nested maps" do
    input = [
      regular_key: %{
        blacklisted: ["foofoofoo", "barbarbar", "bazbazbaz"],
        regular_key: "Other value"
      }
    ]

    expected_output = [
      regular_key: %{
        regular_key: "Other value",
        blacklisted: ["foo******", "bar******", "baz******"]
      }
    ]

    assert ExObfuscator.call(input, [:blacklisted]) == expected_output

    input = [
      blacklisted: %{
        blacklisted: ["foofoofoo", "barbarbar", "bazbazbaz"],
        regular_key: "Other value"
      }
    ]

    expected_output = [
      blacklisted: %{
        blacklisted: ["foo******", "bar******", "baz******"],
        regular_key: "Oth********"
      }
    ]

    assert ExObfuscator.call(input, [:blacklisted]) == expected_output
  end

  test "obfuscates a very complex nested structure containing all possible types" do
    struct = %FooStruct{
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

    list = ["foo", "bar", "baz"]

    keyword_list = [foo: "bar", baz: "xyz"]

    complex_map = %{
      struct: struct,
      struct2: %{struct | map: %{list: list}},
      tuple: {"foo", "bar", %{struct | map: %{list: list, keyword_list: keyword_list}}},
      complex_map: nil
    }

    input = %{blacklisted: %{complex_map | complex_map: complex_map}}

    expected_output = %{
      blacklisted: %{
        complex_map: %{
          complex_map: nil,
          struct: %FooStruct{
            atom: :foo_bar_baz,
            integer: "***",
            map: %{
              bar: "bar******",
              baz: "baz******",
              foo: "foo******",
              nested: %{bar: "bar******", baz: "baz******", foo: "foo******"}
            },
            nested_map: %{not_blacklisted: "oth********", string: "Foo******"},
            not_blacklisted: "oth********",
            string: "Foo******"
          },
          struct2: %FooStruct{
            atom: :foo_bar_baz,
            integer: "***",
            map: %{list: ["***", "***", "***"]},
            nested_map: %{not_blacklisted: "oth********", string: "Foo******"},
            not_blacklisted: "oth********",
            string: "Foo******"
          },
          tuple:
            {"***", "***",
             %FooStruct{
               atom: :foo_bar_baz,
               integer: "***",
               map: %{keyword_list: [foo: "***", baz: "***"], list: ["***", "***", "***"]},
               nested_map: %{not_blacklisted: "oth********", string: "Foo******"},
               not_blacklisted: "oth********",
               string: "Foo******"
             }}
        },
        struct: %FooStruct{
          atom: :foo_bar_baz,
          integer: "***",
          map: %{
            bar: "bar******",
            baz: "baz******",
            foo: "foo******",
            nested: %{bar: "bar******", baz: "baz******", foo: "foo******"}
          },
          nested_map: %{not_blacklisted: "oth********", string: "Foo******"},
          not_blacklisted: "oth********",
          string: "Foo******"
        },
        struct2: %FooStruct{
          atom: :foo_bar_baz,
          integer: "***",
          map: %{list: ["***", "***", "***"]},
          nested_map: %{not_blacklisted: "oth********", string: "Foo******"},
          not_blacklisted: "oth********",
          string: "Foo******"
        },
        tuple:
          {"***", "***",
           %FooStruct{
             atom: :foo_bar_baz,
             integer: "***",
             map: %{keyword_list: [foo: "***", baz: "***"], list: ["***", "***", "***"]},
             nested_map: %{not_blacklisted: "oth********", string: "Foo******"},
             not_blacklisted: "oth********",
             string: "Foo******"
           }}
      }
    }

    assert ExObfuscator.call(input, [:blacklisted]) == expected_output
  end

  test "obfuscates a camelCase keys even if blacklisted snake_case key" do
    input = %{
      "blacklistedKey" => "Some value",
      "blacklisted_key" => "Some value",
      "regular_key" => "foo"
    }

    expected_output = %{
      "blacklistedKey" => "Som*******",
      "blacklisted_key" => "Som*******",
      "regular_key" => "foo"
    }

    assert ExObfuscator.call(input, [:blacklisted_key]) == expected_output
  end

  test "obfuscates a kebab-case keys even if blacklisted snake_case key" do
    input = %{
      "blacklisted-key" => "Some value",
      "blacklisted_key" => "Some value",
      "regular_key" => "foo"
    }

    expected_output = %{
      "blacklisted-key" => "Som*******",
      "blacklisted_key" => "Som*******",
      "regular_key" => "foo"
    }

    assert ExObfuscator.call(input, [:blacklisted_key]) == expected_output
  end

  test "obfuscates a UpperCamelCase keys even if blacklisted snake_case key" do
    input = %{
      "BlacklistedKey" => "Some value",
      "blacklisted_key" => "Some value",
      "regular_key" => "foo"
    }

    expected_output = %{
      "BlacklistedKey" => "Som*******",
      "blacklisted_key" => "Som*******",
      "regular_key" => "foo"
    }

    assert ExObfuscator.call(input, [:blacklisted_key]) == expected_output
  end

  test "obfuscates a keys with spaces even if blacklisted snake_case key" do
    input = %{
      "blacklisted key" => "Some value",
      "blacklisted_key" => "Some value",
      "regular_key" => "foo"
    }

    expected_output = %{
      "blacklisted key" => "Som*******",
      "blacklisted_key" => "Som*******",
      "regular_key" => "foo"
    }

    assert ExObfuscator.call(input, [:blacklisted_key]) == expected_output
  end

  test "allows to completely drop a key" do
    input = %{
      blacklisted_key1: "Some value",
      blacklisted_key2: "Some value",
      regular_key: "Other value"
    }

    expected_output = %{
      blacklisted_key1: "Som*******",
      regular_key: "Other value"
    }

    blacklist = [blacklisted_key1: :obfusacte, blacklisted_key2: :drop]

    assert ExObfuscator.call(input, blacklist) == expected_output
  end

  test "allows to force obfuscating the whole value of a specific key" do
    input = %{
      blacklisted_key: "Some value",
      regular_key: "Other value"
    }

    expected_output = %{
      blacklisted_key: "**********",
      regular_key: "Other value"
    }

    blacklist = [blacklisted_key: :obfuscate_entire_value]

    assert ExObfuscator.call(input, blacklist) == expected_output
  end

  test "allows to configure the visible string length"
  test "allows to configure the max length of obfuscated value"
  test "allows to configure the number of characters when the value will be obfuscated totally"
  test "allows to configure if nil values are supposed to stay nil or be treated as filled value"
  test "allows to configure global case sensitivity"
  test "allows to configure case sensitivity per key"
  test "allows to configure if numberic values are supposed to be obfuscated"
  test "allows to configure if camelCase/kebab-case keys are supposed to be obfuscated (globally)"
  test "allows to configure if camelCase/kebab-case keys are supposed to be obfuscated (per key)"
  test "allows to configure if obfuscate primitives"
  test "allows to switch blacklist to whitelist"
  test "allows to combine blacklist and whitelist"
end
