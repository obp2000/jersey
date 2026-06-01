defmodule JerseyWeb.Plugs.Locale do
  import Plug.Conn

  @default_locale Application.compile_env(:jersey, [JerseyWeb.Gettext, :default_locale], "en")

  @locales Application.compile_env(:jersey, [JerseyWeb.Gettext, :locales], ~w(en ru))

  def init(_default), do: @default_locale

  def call(%Plug.Conn{params: %{"locale" => loc}} = conn, _default) when loc in @locales do
    Gettext.put_locale(JerseyWeb.Gettext, loc)

    conn
    |> assign(:locale, loc)
    |> put_session(:locale, loc)
  end

  def call(conn, _default) do
    locale = get_session(conn, :locale) || @default_locale
    Gettext.put_locale(JerseyWeb.Gettext, locale)
    assign(conn, :locale, locale)
  end
end
