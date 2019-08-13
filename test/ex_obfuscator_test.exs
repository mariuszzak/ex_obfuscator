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
end
