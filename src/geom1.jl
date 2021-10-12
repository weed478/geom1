module geom1

include("geometry.jl")
include("data.jl")
include("analysishelpers.jl")
include("analysis.jl")

function main()
    Analysis.basicclassification()
    Analysis.epsilonvpoints()
    Analysis.widerdiff()
    nothing
end

end # module
