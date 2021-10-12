module Analysis

using ..Geometry
using ..Data
using ..AnalysisHelpers

import LinearAlgebra
import Random

const SEED = 42

function gendatasets(T::Type)::Vector{Dataset{T}}
    Random.seed!(SEED)
    datagens = [
        gendataseta,
        gendatasetb,
        gendatasetc,
        gendatasetd,
    ]
    map(g -> g(T), datagens)
end

function basicclassification()
    # original type
    U = Float64

    Ts = [Float32, Float64]
    
    datasets = gendatasets(U)    

    for d in datasets, T in Ts
        d = convertdataset(T, d)
        plotclassification(
            d,
            AlgoConfig(
                orient3x3,
                LinearAlgebra.det,
                d.etyp,
                "$T-3x3-builtin-$(d.etyp)"
            )
        )
    end
end

function epsilonvpoints()
    T = Float64
    datasets = gendatasets(T)
    for d in datasets
        plotepsilon(
            d,
            AlgoConfig{T}(
                orient3x3,
                LinearAlgebra.det,
                d.etyp,
                "$T-3x3-builtin-$(d.etyp)"
            ),
            range(d.emin, d.emax, length=30)
        )
    end
end

function widerdiff()
    T = Float64
    d = gendatasets(T)[1]
    
    plotcomparison(
        d,
        AlgoConfig{T}(
            orient3x3,
            LinearAlgebra.det,
            d.etyp,
            "$T-3x3-builtin-$(d.etyp)"
        ),
        AlgoConfig{T}(
            orient3x3,
            LinearAlgebra.det,
            d.etyp * 1.2,
            "$T-3x3-builtin-$(d.etyp * 1.2)"
        )
    )
end

end # module Analysis
