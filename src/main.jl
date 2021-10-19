import Pkg
Pkg.activate("$(@__DIR__)/..")
Pkg.instantiate()

include("geom1.jl")
cd("$(@__DIR__)/..")
rm("output", force=true, recursive=true)
mkpath("output")
geom1.main()
