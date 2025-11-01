defmodule CubepubWeb.Components.Sidebar do
  use Phoenix.Component
  import CubepubWeb.CoreComponents
  alias Phoenix.LiveView.JS

  # Route configuration
  @routes [
    %{
      path: "/",
      label: "Projects",
      icon: :folder,
      children: nil
    },
    %{
      path: "/packages",
      label: "Packages",
      icon: :cube,
      children: nil
    },
    %{
      path: "/membership",
      label: "Membership",
      icon: :users,
      children: [
        %{path: "/membership/dashboard", label: "Dashboard"},
        %{path: "/membership/list", label: "List"},
        %{path: "/membership/pricing", label: "Pricing"},
        %{path: "/membership/settings", label: "Setting"}
      ]
    }
  ]

  attr :socket, Phoenix.LiveView.Socket, required: true
  attr :current_path, :string, default: "/"

  def sidebar(assigns) do
    assigns = assign(assigns, :routes, @routes)

    ~H"""
    <aside class="w-64 bg-white border-r border-gray-200 flex-shrink-0">
      <!-- Logo in Sidebar -->
      <div class="p-4 border-b border-gray-200">
        <div class="flex items-center space-x-2">
          <img
            src={
              Phoenix.VerifiedRoutes.static_path(
                @socket,
                "/images/cubepub_logo.svg"
              )
            }
            alt="Cubepub Packages"
            class="h-6"
          />
          <span class="text-lg font-bold text-gray-900">CubePub</span>
          <span class="px-2 py-0.5 text-xs font-semibold text-white bg-violet-400 rounded-full">
            v1.2.0
          </span>
        </div>
      </div>

      <nav class="p-4 space-y-1">
        <div class="px-3 py-2 text-xs font-semibold text-gray-600 uppercase tracking-wider mt-6">
          Application
        </div>

        <%= for route <- @routes do %>
          <%= if route.children do %>
            <!-- Parent item with submenu -->
            <div class="relative">
              <button
                type="button"
                phx-click={
                  JS.toggle(
                    to: "#submenu-#{route.label |> String.downcase() |> String.replace(" ", "-")}"
                  )
                  |> JS.toggle_class("rotate-90",
                    to: "#chevron-#{route.label |> String.downcase() |> String.replace(" ", "-")}"
                  )
                }
                class={[
                  "w-full flex items-center justify-between px-3 py-2 text-sm font-medium rounded-lg transition",
                  active_button_class(route_active?(route, @current_path))
                ]}
              >
                <div class="flex items-center space-x-3">
                  <.icon
                    name={"hero-#{route.icon}"}
                    class={"w-5 h-5 #{active_text_class(route_active?(route, @current_path))}"}
                  />
                  <span>{route.label}</span>
                </div>
                <svg
                  id={"chevron-#{route.label |> String.downcase() |> String.replace(" ", "-")}"}
                  class={[
                    "w-4 h-4 transition-transform",
                    active_text_class(route_active?(route, @current_path))
                  ]}
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M9 5l7 7-7 7"
                  >
                  </path>
                </svg>
              </button>

    <!-- Submenu -->
              <div
                id={"submenu-#{route.label |> String.downcase() |> String.replace(" ", "-")}"}
                class="ml-2 mt-1 space-y-1 hidden relative pl-4"
              >
                <!-- Vertical line -->
                <div class="absolute left-3 top-0 bottom-0 w-px bg-gray-200"></div>

                <%= for child <- route.children do %>
                  <a
                    href={child.path}
                    class={[
                      "flex items-center space-x-2 px-3 py-2 text-sm rounded-lg transition group relative",
                      if(@current_path == child.path, do: "text-cyan-600", else: "text-gray-600")
                    ]}
                  >
                    <span class={[
                      "w-1 h-1 rounded-full group-hover:bg-cyan-200 transition",
                      if(@current_path == child.path, do: "bg-cyan-200", else: "bg-gray-600")
                    ]}>
                    </span>
                    <span>{child.label}</span>
                  </a>
                <% end %>
              </div>
            </div>
          <% else %>
            <!-- Regular navigation item -->
            <a
              href={route.path}
              class={[
                "flex items-center space-x-2 p-3 text-sm font-medium rounded-lg",
                if(@current_path == route.path,
                  do: "bg-sky-50 text-sky-400",
                  else: "text-gray-600 hover:bg-gray-100 transition"
                )
              ]}
            >
              <.icon
                name={"hero-#{route.icon}"}
                class={
                  if @current_path == route.path do
                    "w-5 h-5 text-sky-400"
                  else
                    "w-5 h-5 text-gray-600"
                  end
                }
              />
              <span>{route.label}</span>
            </a>
          <% end %>
        <% end %>
      </nav>
    </aside>
    """
  end

  # Helper functions
  defp route_active?(route, current_path) do
    if route.children do
      Enum.any?(route.children, fn child -> current_path == child.path end)
    else
      current_path == route.path
    end
  end

  defp active_text_class(true), do: "text-cyan-600"
  defp active_text_class(false), do: "text-gray-600"

  defp active_button_class(true), do: "text-cyan-700 bg-cyan-50"
  defp active_button_class(false), do: "text-gray-600 hover:bg-gray-100"
end
