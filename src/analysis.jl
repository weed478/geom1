module Analysis

using ..Geometry
using ..Data
using ..AnalysisHelpers

using Plots
using BenchmarkTools
using LinearAlgebra: det
using DataFrames
using CSV

function gendatasets(::Type{T})::Vector{Dataset{T}} where T
    datagens = [
        gendataseta,
        gendatasetb,
        gendatasetc,
        gendatasetd,
    ]
    map(g -> g(T), datagens)
end

function benchmark()
    d = gendataseta(Float64)
    println("benchmark-builtin")
    display(@benchmark $d.pnts .|> $(p -> orient2x2(det, d.etyp, d.line, p)))
    println("benchmark-manual")
    display(@benchmark $d.pnts .|> $(p -> orient2x2(manualdet, d.etyp, d.line, p)))
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
    dets = [det, manualdet]
    datasets = gendatasets(Float32)

    for d=datasets, T=Ts
        d = Dataset(T, d)
        e = findeps(d, 6, 0)
        for orient=orients, detfn=dets
            plotclassification(
                d,
                AlgoConfig{T}(
                    orient,
                    detfn,
                    e,
                    "$T-$orient-$detfn-$e"
                )
            )
        end
    end
end

function maketables()
    datasets = gendatasets(Float32)
    Ts = [Float32, Float64]
    orients = [orient2x2, orient3x3]
    dets = [det, manualdet]

    getstats(d, orient) =
        count(d.pnts) do P
            orient(P) < 0
        end,
        count(d.pnts) do P
            orient(P) == 0
        end,
        count(d.pnts) do P
            orient(P) > 0
        end
    
    for d=datasets
        title = "table-$(d.name)"
        println(title)

        emin, emax = findepsrange(d)
        expmin = floor(Int, max(1.f-38, emin) |> log10)
        expmax = ceil(Int, min(1.f38, emax) |> log10)

        df = DataFrame()

        for e in 10.f0 .^ (expmin:expmax)
            row = DataFrame(:e => e)
            for T=Ts
                d = Dataset(T, d)
                e = T(e)
                for orient=orients, detfn=dets
                    neg, line, pos = getstats(d, P -> orient(detfn, e, d.line, P))
                    insertcols!(row, "$T-$orient-$detfn" => line)
                end
            end
            df = vcat(df, row)
        end

        CSV.write("output/$title-tex.txt", df, delim='&', newline="\\\\\n")
    end
end

function ddoubleorder()
    T = Float64
    d = Dataset(T, gendatasetd(Float32))
    e = findeps(d, 50, 0)
    plotclassification(
        d,
        AlgoConfig{T}(
            orient3x3,
            det,
            e,
            "D-double-order"
        )
    )
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
    for d=gendatasets(Float64), det=[LinearAlgebra.det, manualdet], orient=[orient2x2, orient3x3]
        U = Float64
        for T=[Float16, Float32]
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
end

end # module Analysis
