[
  plugins: [Phoenix.LiveView.HTMLFormatter],
  inputs: ["mix.exs", "config/*.exs"],
  subdirectories: ["apps/*"],
   import_deps: [:ash_authentication]
]
