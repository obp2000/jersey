defmodule JerseyWeb.ProductForm do
  use JerseyWeb, :html
  alias Phoenix.LiveView.UploadConfig

  attr :upload, UploadConfig, required: true
  attr :class, :string, default: ""

  def image_field(assigns) do
    ~H"""
    <section
      phx-drop-target={@upload.ref}
      class={["phx-drop-target-active:scale-105 border border-blue-500 p-2 rounded mb-2", @class]}
    >
      <.live_file_input upload={@upload} />
      <article :for={entry <- @upload.entries} class="upload-entry">
        <.upload_preview entry={entry} />
        <.upload_progress entry={entry} />
        <.cancel_upload_button entry={entry} />
        <.upload_errors_list upload_errors={upload_errors(@upload, entry)} />
      </article>
      <.upload_errors_list upload_errors={upload_errors(@upload)} />
    </section>
    """
  end

  attr :entry, :map, required: true

  def upload_preview(assigns) do
    ~H"""
    <figure>
      <.live_img_preview entry={@entry} width="60" />
      <figcaption>{@entry.client_name}</figcaption>
    </figure>
    """
  end

  attr :entry, :map, required: true

  def upload_progress(assigns) do
    ~H"""
    <progress value={@entry.progress} max="100">{@entry.progress}% </progress>
    """
  end

  attr :entry, :map, required: true

  def cancel_upload_button(assigns) do
    ~H"""
    <button
      type="button"
      phx-click="cancel-upload"
      phx-value-ref={@entry.ref}
      aria-label="cancel"
    >
      &times;
    </button>
    """
  end

  defp error_to_string(:too_large), do: dgettext("product", "File is too large")

  defp error_to_string(:too_many_files),
    do: dgettext("product", "You have selected too many files")

  defp error_to_string(:not_accepted),
    do: dgettext("product", "You have selected an unacceptable file type")

  attr :upload_errors, :list, required: true

  def upload_errors_list(assigns) do
    ~H"""
    <p :for={err <- @upload_errors} class="alert alert-danger">
      {error_to_string(err)}
    </p>
    """
  end
end
