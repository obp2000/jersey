defmodule Jersey.Clients.PostcalcClient do
  @moduledoc """
  Client for interacting with the Postcalc API.
  """

  alias Req.Response

  @api_key Application.compile_env(:jersey, :postcalc_key)
  @base_url Application.compile_env(:jersey, :postcalc_url)
  @from_pindex Application.compile_env(:jersey, :from_pindex)

  def get_post_cost(pindex, weight) do
    params = [f: @from_pindex, t: pindex, w: weight, o: "json", v: 0, key: @api_key]

    case make_request(params) do
      {:ok, body} ->
        (body["Отправления"]["ЦеннаяПосылка"]["Тариф"] || "0") |> String.replace(",", ".")

      {:error, reason} ->
        reason
    end
  end

  # {:ok,
  #  %{
  #    "API" => "2.1",
  #    "Currency" => %{
  #      "Code" => "RUB",
  #      "Coeff" => "1.0",
  #      "Name" => "Российский рубль"
  #    },
  #    "NumReqToday" => 8,
  #    "Status" => "OK",
  #    "_request" => %{
  #      "f" => "153038",
  #      "key" => "test",
  #      "o" => "json",
  #      "t" => "190000",
  #      "v" => "0",
  #      "w" => "1000"
  #    },
  #    "_server" => %{
  #      "HTTP_ACCEPT_ENCODING" => "gzip",
  #      "HTTP_HOST" => "test.postcalc.ru",
  #      "HTTP_USER_AGENT" => "req/0.5.17",
  #      "REMOTE_ADDR" => "95.27.21.176",
  #      "SERVER_ADDR" => "173.230.134.78"
  #    },
  #    "_timing" => %{
  #      "End" => "2026-05-14  14:37:02.0835 MSK",
  #      "ExtRequest" => "792.5",
  #      "LocalCalc" => "70.4",
  #      "Start" => "2026-05-14  14:37:01.2036 MSK",
  #      "Total" => "879.9"
  #    },
  #    "_vars" => %{
  #      "Box" => "s",
  #      "Corp" => 1,
  #      "Country" => "RU",
  #      "Date" => "2026-05-14",
  #      "From" => "153038",
  #      "IBase" => "p",
  #      "Key" => "test",
  #      "Parcels" => "pv,p1,em",
  #      "Partible" => 0,
  #      "Services" => "",
  #      "Size" => "",
  #      "To" => "190000",
  #      "VAT" => 1,
  #      "Valuation" => "0",
  #      "Volume" => "",
  #      "Weight" => 1000
  #    },
  #    "Куда" => %{
  #      "Адрес" => "г Санкт-Петербург, Почтамтская ул, 9А",
  #      "Индекс" => "190000",
  #      "Название" => "Санкт-Петербург"
  #    },
  #    "Откуда" => %{
  #      "Адрес" => "Ивановская область, г Иваново, Текстильщиков пр-кт, 117",
  #      "Индекс" => "153038",
  #      "Название" => "Иваново 38"
  #    },
  #    "Отправления" => %{
  #      "EMS" => %{
  #        "Code" => "em",
  #        "Source" => "tariff.pochta.ru",
  #        "Доставка" => "891.00",
  #        "Количество" => 1,
  #        "Название" => "Курьерская доставка EMS",
  #        "НаложенныйПлатеж" => 0,
  #        "ОценкаПолная" => "0.00",
  #        "ПредельныйВес" => "31500",
  #        "СрокДоставки" => "2-4",
  #        "СрокДоставкиОписание" => "",
  #        "Страховка" => "0.00",
  #        "Тариф" => "891.00"
  #      },
  #      "Посылка1Класс" => %{
  #        "Code" => "p1",
  #        "Source" => "tariff.pochta.ru",
  #        "Доставка" => "537.00",
  #        "Количество" => 1,
  #        "Название" => "Посылка 1 класса",
  #        "НаложенныйПлатеж" => 0,
  #        "ОценкаПолная" => "0.00",
  #        "ПредельныйВес" => "5000",
  #        "СрокДоставки" => "3-4",
  #        "СрокДоставкиОписание" => "",
  #        "Страховка" => "0.00",
  #        "Тариф" => "537.00"
  #      },
  #      "ЦеннаяПосылка" => %{
  #        "Code" => "pv",
  #        "Source" => "tariff.pochta.ru",
  #        "Доставка" => "448.00",
  #        "Количество" => 1,
  #        "Название" => "Ценная/обыкновенная посылка",
  #        "НаложенныйПлатеж" => 0,
  #        "ОценкаПолная" => "0.00",
  #        "ПредельныйВес" => "20000",
  #        "СрокДоставки" => "4",
  #        "СрокДоставкиОписание" => "",
  #        "Страховка" => "0.00",
  #        "Тариф" => "448.00"
  #      }
  #    }
  #  }}

  defp make_request(params) do
    case Req.get(@base_url, params: params) do
      {:ok, %Response{status: status, body: body}} when status in 200..299 ->
        {:ok, body}

      {:ok, %Response{status: status, body: body}} ->
        {:error, {status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
