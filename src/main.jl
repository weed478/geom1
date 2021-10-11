include("geom1.jl")
rm("output", force=true, recursive=true)
mkpath("output")
geom1.main()
