defmodule BlockScoutWeb.AddressTokenBalanceController do
  use BlockScoutWeb, :controller

  alias BlockScoutWeb.AccessHelpers
  alias Explorer.{Chain, Market}
  alias Explorer.Chain.Address
  alias Indexer.Fetcher.TokenBalanceOnDemand

  @decimal_zero Decimal.new(0)
  def index(conn, %{"address_id" => address_hash_string} = params) do
    with true <- ajax?(conn),
         {:ok, address_hash} <- Chain.string_to_address_hash(address_hash_string) do
      token_balances =
        address_hash
        |> Chain.fetch_last_token_balances()

      tokens_not_in_address =
        address_hash
        |> Chain.fetch_tokens_not_in_address()
        |> Enum.map(fn token ->
          %{
            token_address: elem(token, 0),
            token_type: elem(token, 1)
          }
        end)

      Task.start_link(fn ->
        TokenBalanceOnDemand.trigger_fetch(address_hash, token_balances)
      end)

      if length(tokens_not_in_address) > 0 do
        Task.start_link(fn ->
          TokenBalanceOnDemand.check_and_update_unfetched_token_balances(address_hash, tokens_not_in_address)
        end)
      end

      token_balances_with_price =
        token_balances
        |> Enum.filter(fn {balance, _, _} -> Decimal.cmp(balance.value, @decimal_zero) != :eq end)
        |> Market.add_price()

      case AccessHelpers.restricted_access?(address_hash_string, params) do
        {:ok, false} ->
          conn
          |> put_status(200)
          |> put_layout(false)
          |> render("_token_balances.html",
            address_hash: Address.checksum(address_hash),
            token_balances: token_balances_with_price,
            conn: conn
          )

        _ ->
          conn
          |> put_status(200)
          |> put_layout(false)
          |> render("_token_balances.html",
            address_hash: Address.checksum(address_hash),
            token_balances: [],
            conn: conn
          )
      end
    else
      _ ->
        not_found(conn)
    end
  end
end
