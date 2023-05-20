defmodule UiWeb.OrdersLive.Table do
  @moduledoc false

  use UiWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <table class="table table-hover">
      <thead>
        <tr>
          <th>Id</th>
          <th>Trade Id</th>
          <th>Symbol</th>
          <th>Price</th>
          <th>Original Quantity</th>
          <th>Executed Quantity</th>
          <th>Side</th>
          <th>Status</th>
          <th>Type</th>
          <th>Time</th>
        </tr>
      </thead>
      <tbody>
      <.live_component
        module={__MODULE__.Row}
        :for={order <- @orders_data}
        id={"setting-row-#{order.id}"}
        order={order} />
      </tbody>
    </table>
    """
  end
end
