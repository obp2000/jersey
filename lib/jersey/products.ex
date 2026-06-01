defmodule Jersey.Products do
  @moduledoc """
  The Products context.
  """

  import Ecto.Query, warn: false

  alias Jersey.Repo
  alias Jersey.Products.Product

  @default_page 1
  @default_per_page 20

  def default_per_page, do: @default_per_page
  def default_page, do: @default_page

  @doc """
  Returns the list of products with pagination.

  ## Examples

      iex> list_products()
      [%Product{}, ...]

  """
  def list_products() do
    Repo.all(Product)
  end

  def paginate_products(params) do
    Product.Query.order_by_inserted_at() |> Repo.paginate(params)
  end

  @doc """
  Returns total count of products.
  """
  def count_products do
    Repo.aggregate(Product, :count)
  end

  @doc """
  Gets a single product.

  Raises `Ecto.NoResultsError` if the Product does not exist.

  ## Examples

      iex> get_product!(123)
      %Product{}

      iex> get_product!(456)
      ** (Ecto.NoResultsError)

  """
  def get_product!(id), do: Repo.get!(Product, id)

  @doc """
  Creates a product.

  ## Examples

      iex> create_product(%{field: value})
      {:ok, %Product{}}

      iex> create_product(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_product(attrs, uploaded_files \\ []) do
    %Product{}
    |> Product.changeset(attrs, uploaded_files)
    |> Repo.insert()
  end

  @doc """
  Updates a product.

  ## Examples

      iex> update_product(product, %{field: new_value})
      {:ok, %Product{}}

      iex> update_product(product, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_product(%Product{} = product, attrs, uploaded_files \\ []) do
    product
    |> Product.changeset(attrs, uploaded_files)
    |> Repo.update()
  end

  @doc """
  Deletes a product.

  ## Examples

      iex> delete_product(product)
      {:ok, %Product{}}

      iex> delete_product(product)
      {:error, %Ecto.Changeset{}}

  """
  def delete_product(%Product{} = product) do
    product |> Product.changeset() |> Repo.delete()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking product changes.

  ## Examples

      iex> change_product(product)
      %Ecto.Changeset{data: %Product{}}

  """
  def change_product(%Product{} = product, attrs \\ %{}, uploaded_files \\ []) do
    Product.changeset(product, attrs, uploaded_files)
  end

  def search_products(text) do
    Product.Query.search(text) |> Repo.all()
  end
end
