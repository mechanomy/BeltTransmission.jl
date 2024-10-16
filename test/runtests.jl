using TestItemRunner # https://github.com/julia-vscode/TestItemRunner.jl 
println("BeltTransmission:")
@run_package_tests verbose=true

# println("BeltTransmission.SynchronousBeltTable:")
# @run_package_tests verbose=true filter=ti->(occursin("SynchronousBeltTable", ti.filename))

# println("BeltTransmission.Optimizer:")
# @run_package_tests verbose=true filter=ti->(occursin("Optimizer", ti.filename))


# also run all examples to detect errors..
# include("../exes/BeltDesign.jl")
# include("../exes/BeltDesign.jl")
# include("../exes/BeltDesign.jl")

# close("all")