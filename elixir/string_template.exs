defmodule StringTemplate do
  def replace_placeholders(sections) do
    # template
    template = sections |> put_placeholders()
    # rules
    {pattern, replacement} = template |> generate_replacement_rules()
    # get string template
    string_template = template |> inspect()
    # replace placeholders
    {result, _} = string_template |> String.replace(pattern, replacement) |> Code.eval_string()
    result
  end

  # Generate replacement rules according to needs
  def generate_replacement_rules(sections) do
    {reset, no_reset} =
      sections
      |> Enum.split_with(& &1["reset_lesson_position"])

    # three types that need to start counting from 1
    positions =
      (reset |> Enum.map(&lesson_positions/1)) ++
        [
          no_reset |> Enum.flat_map(&lesson_positions/1) |> List.wrap(),
          sections |> Enum.map(& &1["position"]) |> List.wrap()
        ]

    rules =
      positions
      |> Enum.map(fn placeholder ->
        placeholder
        |> Enum.map(&Integer.to_string/1) # String.replace/4 pattern need a list of strings
        |> Enum.with_index(1)
      end)
      |> List.flatten()
      |> Map.new()

    {
      Map.keys(rules),
      &Integer.to_string(rules[&1])
    }
  end

  # Put unique placeholder
  def put_placeholders(list) do
    list
    |> Enum.map(fn
      %{"lessons" => lessons} = item ->
        item
        |> Map.put("position", System.unique_integer())
        |> Map.put("lessons", put_placeholders(lessons))

      item ->
        item
        |> Map.put("position", System.unique_integer())
    end)
  end

  def lesson_positions(sections) do
    sections
    |> Map.get("lessons")
    |> Enum.map(& &1["position"])
  end
end

sections = [
  %{
    "title" => "Getting started",
    "reset_lesson_position" => false,
    "lessons" => [
      %{"name" => "Welcome"},
      %{"name" => "Installation"}
    ]
  },
  %{
    "title" => "Basic operator",
    "reset_lesson_position" => false,
    "lessons" => [
      %{"name" => "Addition / Subtraction"},
      %{"name" => "Multiplication / Division"}
    ]
  },
  %{
    "title" => "Advanced topics",
    "reset_lesson_position" => true,
    "lessons" => [
      %{"name" => "Mutability"},
      %{"name" => "Immutability"}
    ]
  }
]

expected_result = [
  %{
    "title" => "Getting started",
    "reset_lesson_position" => false,
    "position" => 1,
    "lessons" => [
      %{"name" => "Welcome", "position" => 1},
      %{"name" => "Installation", "position" => 2}
    ]
  },
  %{
    "title" => "Basic operator",
    "reset_lesson_position" => false,
    "position" => 2,
    "lessons" => [
      %{"name" => "Addition / Subtraction", "position" => 3},
      %{"name" => "Multiplication / Division", "position" => 4}
    ]
  },
  %{
    "title" => "Advanced topics",
    "reset_lesson_position" => true,
    "position" => 3,
    "lessons" => [
      %{"name" => "Mutability", "position" => 1},
      %{"name" => "Immutability", "position" => 2}
    ]
  }
]

^expected_result = StringTemplate.replace_placeholders(sections)
