defmodule PiEx.Protocol.EncodeTest do
  use ExUnit.Case, async: true

  alias PiEx.Protocol
  alias PiEx.TestFixtures.CommandShapeMatrix

  test "minimal command encodings match the shape matrix" do
    for %{name: name, minimal: command, expected_minimal: expected, forbidden_keys: forbidden_keys} <-
          CommandShapeMatrix.cases() do
      decoded = command |> Protocol.encode() |> JSON.decode!()

      assert decoded == expected, "minimal encoding mismatch for #{name}: #{inspect(decoded)}"

      for forbidden_key <- forbidden_keys do
        refute Map.has_key?(decoded, forbidden_key),
               "minimal encoding for #{name} leaked forbidden key #{forbidden_key}"
      end
    end
  end

  test "full command encodings match the shape matrix" do
    for %{name: name, full: command, expected_full: expected, forbidden_keys: forbidden_keys} <-
          CommandShapeMatrix.cases() do
      decoded = command |> Protocol.encode() |> JSON.decode!()

      assert decoded == expected, "full encoding mismatch for #{name}: #{inspect(decoded)}"

      for forbidden_key <- forbidden_keys do
        refute Map.has_key?(decoded, forbidden_key),
               "full encoding for #{name} leaked forbidden key #{forbidden_key}"
      end
    end
  end

  test "encodings never include nil values" do
    for %{name: name, minimal: minimal, full: full} <- CommandShapeMatrix.cases(), command <- [minimal, full] do
      decoded = command |> Protocol.encode() |> JSON.decode!()

      refute Enum.any?(decoded, fn {_key, value} -> is_nil(value) end),
             "encoding for #{name} contains nil values: #{inspect(decoded)}"
    end
  end
end