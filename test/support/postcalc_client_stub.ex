defmodule Jersey.Clients.PostcalcClientStub do
  @moduledoc false

  alias Req.Response

  # This stub is used from PostcalcClient via the :postcalc_http_client compile env.
  # It makes tests deterministic without requiring Mox.
  #
  # Rules:
  # - w == 1001 => tariff with comma
  # - pindex == "190000" and w == 1000 => tariff with dot
  # - pindex == "190001" => missing tariff
  # - pindex == "190002" => request error
  def get(_base_url, params: params) do
    pindex = Keyword.get(params, :t)
    w = Keyword.get(params, :w)
    dec_1000 = Decimal.new("1000")
    dec_1001 = Decimal.new("1001")

    case {pindex, w} do
      {"190000", ^dec_1000} ->
        {:ok,
         %Response{
           status: 200,
           body: %{
             "Отправления" => %{
               "ЦеннаяПосылка" => %{"Тариф" => "448.00"}
             }
           }
         }}

      {"190000", ^dec_1001} ->
        {:ok,
         %Response{
           status: 200,
           body: %{
             "Отправления" => %{
               "ЦеннаяПосылка" => %{"Тариф" => "448,10"}
             }
           }
         }}

      {"190001", _w} ->
        {:ok,
         %Response{
           status: 200,
           body: %{
             "Отправления" => %{
               "ЦеннаяПосылка" => %{}
             }
           }
         }}

      {"190002", _w} ->
        {:error, :timeout}

      {"190003", _w} ->
        {:ok,
         %Response{
           status: 500,
           body: %{"error" => "boom"}
         }}

      _ ->
        {:ok,
         %Response{
           status: 200,
           body: %{
             "Отправления" => %{
               "ЦеннаяПосылка" => %{"Тариф" => "0"}
             }
           }
         }}
    end
  end
end
