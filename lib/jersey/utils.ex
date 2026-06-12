# lib/jersey/utils/params_helper.ex
defmodule Jersey.Utils do
  def maybe_decode_live_select_value(attrs, field) do
    with value when is_binary(value) and byte_size(value) > 0 <- Map.get(attrs, field),
         %{"id" => _id} = decoded_value <- LiveSelect.decode(value) do
      put_in(attrs, [field], AtomizeKeys.atomize_string_keys(decoded_value))
    else
      _ -> attrs
    end
  end

  def get_fields(changeset, fields) when is_struct(changeset, Ecto.Changeset) do
    Enum.reduce(fields, %{}, fn field, acc ->
      Map.put(acc, field, Ecto.Changeset.get_field(changeset, field))
    end)
  end
end
