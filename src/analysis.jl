module Analysis

using ..Geometry
using ..Data
using ..AnalysisHelpers

using Plots

import LinearAlgebra
import Random

const SEED = 42

function gendatasets(::Type{T})::Vector{Dataset{T}} where T
    Random.seed!(SEED)
    datagens = [
        gendataseta,
        gendatasetb,
        gendatasetc,
        gendatasetd,
    ]
    map(g -> g(T), datagens)
end

function plotdatasets()
    T = Float64
    for data in gendatasets(T)
        title = "dataset-$(data.name)"
        println(title)
        scatter(
            Tuple.(data.pnts),
            markersize=data.markersize,
            markeropacity=0.4,
            markerstrokewidth=0,
            color=:blue,
            label=false,
            ratio=1,
            title=title,
        )
        savefig("output/$title.png")
    end
end

function basicclassification()
    Ts = [Float32, Float64]
    orients = [orient2x2, orient3x3]
    dets = [LinearAlgebra.det, manualdet]
    datasets = gendatasets(Float32)

    for d=datasets, T=Ts, orient=orients, det=dets
        d = Dataset(T, d)
        plotclassification(
            d,
            AlgoConfig{T}(
                orient,
                det,
                d.etyp,
                "$T-$orient-$det"
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
                "$(d.emin)-$(d.emax)"
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
            "$(d.etyp)"
        ),
        AlgoConfig{T}(
            orient3x3,
            LinearAlgebra.det,
            d.etyp * 1.2,
            "$(d.etyp * 1.2)"
        )
    )

    d = gendatasets(T)[4]

    emin = 0
    emax = d.emax
    e1 = emin + 0.1 * (emax - emin)
    e2 = emin + 0.2 * (emax - emin)

    plotcomparison(
        d,
        AlgoConfig{T}(
            orient3x3,
            LinearAlgebra.det,
            e1,
            "$e1"
        ),
        AlgoConfig{T}(
            orient3x3,
            LinearAlgebra.det,
            e2,
            "$e2"
        )
    )
end

function detcomp()
    T = Float64
    for d=gendatasets(T)
        for det=[LinearAlgebra.det, manualdet]
            plotcomparison(
                d,
                AlgoConfig{T}(
                    orient3x3,
                    det,
                    d.etyp,
                    "3x3-$det"
                ),
                AlgoConfig{T}(
                    orient2x2,
                    det,
                    d.etyp,
                    "2x2-$det"
                )
            )
        end

        for orient=[orient2x2, orient3x3]
            plotcomparison(
                d,
                AlgoConfig{T}(
                    orient,
                    LinearAlgebra.det,
                    d.etyp,
                    "$orient-builtin"
                ),
                AlgoConfig{T}(
                    orient,
                    manualdet,
                    d.etyp,
                    "$orient-manual"
                )
            )
        end
    end
end

function typecomp()
    for d=gendatasets(Float32), det=[LinearAlgebra.det, manualdet], orient=[orient2x2, orient3x3]
        T = Float32
        U = Float64
        plotcomparison(
            d,
            AlgoConfig{T}(
                orient,
                det,
                T(d.etyp),
                "$T-$orient-$det"
            ),
            AlgoConfig{U}(
                orient,
                det,
                U(d.etyp),
                "$U-$orient-$det"
            )
        )
    end
end

end # module Analysis
