import Pkg
# install packages
Pkg.activate("$(@__DIR__)/..")
Pkg.instantiate()

include("geom1.jl")
cd("$(@__DIR__)/..")
# prepare output dir
rm("output", force=true, recursive=true)
mkpath("output")

geom1.main()
