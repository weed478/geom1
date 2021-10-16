module geom1

include("geometry.jl")
include("data.jl")
include("analysishelpers.jl")
include("analysis.jl")

function main()
    jobs = [
        Analysis.plotdatasets,
        Analysis.basicclassification,
        Analysis.epsilonvpoints,
        Analysis.widerdiff,
        Analysis.detcomp,
        Analysis.typecomp,
    ]

    for (i, j) in enumerate(jobs)
        println("$i/$(length(jobs))")
        j()
    end

    nothing
end

end # module
