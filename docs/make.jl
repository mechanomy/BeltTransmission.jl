using Documenter
using DocumenterTools
using DocStringExtensions
using BeltTransmission

makedocs(
  sitename="BeltTransmission.jl",
  modules=[BeltTransmission],
  root = joinpath(dirname(pathof(BeltTransmission)), "..", "docs"),
  source = "src",
  build = "build",
  clean=true,
  doctest=true,
  # repo = "github.com/mechanomy/BeltTransmission.jl.git", this will be set correctly, automatically, unless set here
  draft=false,
  checkdocs=:all,
  # linkcheck=true, fails to find internal links to bookmarks..
  )

# compile custom theme scss in to css, copying over the default themes
DocumenterTools.Themes.compile("docs/src/assets/themes/documenter-mechanomy.scss", "docs/build/assets/themes/documenter-dark.css")
DocumenterTools.Themes.compile("docs/src/assets/themes/documenter-mechanomy.scss", "docs/build/assets/themes/documenter-light.css")

deploydocs(
  root = joinpath(dirname(pathof(BeltTransmission)), "..", "docs"),
  target = "build",
  dirname = "",
  repo = "github.com/mechanomy/BeltTransmission.jl.git",
  branch = "gh-pages",
  deps = nothing, 
  make = nothing,
  devbranch = "main",
  devurl = "dev",
  versions = ["stable" => "v^", "v#.#", "dev" => "dev"],
  forcepush = false,
  deploy_config = Documenter.auto_detect_deploy_system(),
  push_preview = false,
)

