# following https://juliadocs.github.io/Documenter.jl/stable/man/guide/

using Documenter
using BeltTransmission


# https://github.com/cscherrer/MeasureTheory.jl/blob/master/docs/make.jl
# DocMeta.setdocmeta!(BeltTransmission, :DocTestSetup, :(using BeltTransmission); recursive = true)

makedocs(
  sitename="BeltTransmission.jl",
  modules=[BeltTransmission] 
  )


