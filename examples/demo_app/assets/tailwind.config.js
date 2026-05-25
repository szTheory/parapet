// Tailwind CSS configuration for the Parapet demo app.
// The content array includes the generated Operator UI LiveView files so that
// all Tailwind classes used by the Operator UI are retained after purge.
module.exports = {
  content: [
    "./js/**/*.js",
    "../lib/demo_app_web/**/*.{ex,heex}",
    "../lib/demo_app_web/live/parapet/**/*.ex",
    "../../../priv/templates/parapet.gen.ui/*.eex"
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
