module geom1

include("geometry.jl")
include("data.jl")
include("analysishelpers.jl")
include("analysis.jl")

import Random

function main()
    Random.seed!(42)

    jobs = [
        Analysis.benchmark,
        Analysis.plotdatasets,
        Analysis.basicclassification,
        Analysis.maketables,
        Analysis.ddoubleorder,
        # Analysis.epsilonvpoints,
        # Analysis.widerdiff,
        # Analysis.detcomp,
        # Analysis.typecomp,
    ]

    for (i, j) in enumerate(jobs)
        println("$i/$(length(jobs))")
        j()
    end

    nothing
end

end # module
