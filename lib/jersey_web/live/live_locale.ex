defmodule JerseyWeb.LiveLocale do
  @moduledoc """
  Sets the Gettext locale for LiveViews from the session.
  """

  @default_locale Application.compile_env(:jersey, [JerseyWeb.Gettext, :default_locale], "en")

  def on_mount(:default, _params, session, socket) do
    locale = session["locale"] || @default_locale
    Gettext.put_locale(JerseyWeb.Gettext, locale)
    {:cont, socket}
  end
end
