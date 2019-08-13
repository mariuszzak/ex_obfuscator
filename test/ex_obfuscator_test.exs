defmodule ExObfuscatorTest do
  use ExUnit.Case
  doctest ExObfuscator

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

  test "obfuscates a very long string value"
  test "obfuscates a numeric value"
  test "obfuscates a boolean value"
  test "obfuscates a struct"
  test "obfuscates a tuple"
  test "obfuscates a nested map"
  test "obfuscates a nested map with a tuple"
  test "obfuscates a nested map with a tuple with a map"
  test "obfuscates a tuple with a map"
  test "obfuscates a tuple with a tuple"
  test "obfuscates a list"
  test "obfuscates a list of maps"
  test "obfuscates a list of tuples"
  test "obfuscates a list of structs"
  test "allows to completely drop a key"
  test "allows to force obfuscating the whole value of a specific key"
  test "allows to configure the visible string length"
  test "allows to configure the max length of obfuscated value"
end
