defmodule DemoAppWeb.Layouts do
  @moduledoc false
  use DemoAppWeb, :html

  def root(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <.live_title>Demo App</.live_title>
        <meta name="csrf-token" content={get_csrf_token()} />
        <link rel="stylesheet" href={~p"/assets/app.css"} />
      </head>
      <body>
        {@inner_content}
        <script defer src={~p"/assets/app.js"}></script>
      </body>
    </html>
    """
  end

  def app(assigns) do
    ~H"""
    {@inner_content}
    """
  end
end
