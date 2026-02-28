defmodule PiEx.ShapeCompletenessTest do
  use ExUnit.Case, async: true

  alias PiEx.TestFixtures.CommandShapeMatrix

  test "every command module has a command shape matrix entry" do
    command_modules = command_modules_from_source()
    covered_modules = CommandShapeMatrix.covered_modules()

    assert covered_modules == command_modules,
           "command shape matrix coverage mismatch\n" <>
             "covered: #{inspect(covered_modules)}\n" <>
             "source: #{inspect(command_modules)}"
  end

  test "every command case includes minimal and full expected shapes" do
    for %{name: name, expected_minimal: minimal, expected_full: full} <- CommandShapeMatrix.cases() do
      assert is_map(minimal), "#{name} missing expected_minimal map"
      assert is_map(full), "#{name} missing expected_full map"
      assert Map.has_key?(minimal, "type"), "#{name} expected_minimal missing type"
      assert Map.has_key?(full, "type"), "#{name} expected_full missing type"
    end
  end

  defp command_modules_from_source do
    "lib/pi_ex/command/*.ex"
    |> Path.wildcard()
    |> Enum.map(fn path ->
      content = File.read!(path)
      [_, module_name] = Regex.run(~r/defmodule\s+([A-Za-z0-9_.]+)/, content)
      module_name |> String.split(".") |> Module.concat()
    end)
    |> Enum.sort()
  end
end
