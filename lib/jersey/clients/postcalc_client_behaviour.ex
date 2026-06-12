defmodule Jersey.Clients.PostcalcClientBehaviour do
  @moduledoc """
  Behaviour for Postcalc API client.
  """

  @doc """
  Gets post cost from Postcalc API for given destination pindex and weight.

  ## Parameters
    - pindex: Destination postal index (6-digit string)
    - weight: Package weight in grams

  ## Returns
    - String representation of the cost (e.g., "448.00")
    - Error message string if request fails
  """
  @callback get_post_cost(pindex :: String.t(), weight :: integer() | float() | String.t()) ::
              String.t()
end
