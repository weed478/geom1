module geom1

include("geometry.jl")
include("data.jl")

using .Geometry
using .Data

using LinearAlgebra: det
using Plots

# configuration for the classifier
struct AlgoConfig{T}
    e::T
    orientfn
    det::String
    orient::String
end

function manualdet(M::Matrix{T})::T where T
    if size(M) == (2, 2)
        M[1,1] * M[2,2] - M[1,2] * M[2,1]
    elseif size(M) == (3, 3)
          M[1,1] * M[2,2] * M[3,3]
        + M[1,2] * M[2,3] * M[3,1]
        + M[1,3] * M[2,1] * M[3,2]
        - M[1,3] * M[2,2] * M[3,1]
        - M[1,2] * M[2,1] * M[3,3]
        - M[1,1] * M[2,3] * M[3,2]
    else
        error("Invalid matrix size $(size(M))")
    end
end

# scatter plot of points
function plotclassification(data::Dataset{T}) where T
    e = data.e
    pnts = data.pnts
    AB = data.line
    orientation(P) = pointorientationdet3x3(det, e, P, AB)

    title = "class-$(data.name)-$T-3x3-builtin-$e"
    println(title)

    pntsline = filter(pnts) do P
        orientation(P) == 0
    end

    pntsneg = filter(pnts) do P
        orientation(P) < 0
    end

    pntspos = filter(pnts) do P
        orientation(P) > 0
    end

    # plot with all points (colors representing classes) and the line used for classification
    pltcombined = plot(
        ratio=1,
        dpi=600,
        title=title,
    )

    scatter!(pltcombined,
        Tuple.(pntsneg),
        color=:green,
        label="neg",
        markersize=data.markersize,
        markeropacity=0.4,
        markerstrokewidth=0,
    )

    scatter!(pltcombined,
        Tuple.(pntspos),
        color=:blue,
        label="pos",
        markersize=data.markersize,
        markeropacity=0.4,
        markerstrokewidth=0,
    )

    scatter!(pltcombined,
        Tuple.(pntsline),
        color=:red,
        label="on line",
        markersize=data.markersize,
        markeropacity=0.4,
        markerstrokewidth=0,
    )

    # get area bounds
    x1 = minimum(getfield.(pnts, :x))
    x2 = maximum(getfield.(pnts, :x))

    # move points away from eachother
    x1 += T(.1) * (x1 - x2)
    x2 += T(.1) * (x2 - x1)
    
    # draw line using 2 points
    # (x1, f(x1)), (x2, f(x2))
    l = tofunctional(AB)
    plot!(pltcombined,
        [x1, x2] .|> x -> (x, f(l)(x)),
        lw=6,
        opacity=0.2,
        color=:black,
        label="line",
    )

    # individual plots

    pltneg = scatter(
        Tuple.(pntsneg),
        markersize=data.markersize,
        markeropacity=0.4,
        markerstrokewidth=0,
        lims=(x1, x2),
        color=:green,
        label="neg",
        ratio=1,
        dpi=600,
        title=title,
    )

    pltpos = scatter(
        Tuple.(pntspos),
        markersize=data.markersize,
        markeropacity=0.4,
        markerstrokewidth=0,
        lims=(x1, x2),
        color=:blue,
        label="pos",
        ratio=1,
        dpi=600,
        title=title,
    )

    pltline = scatter(
        Tuple.(pntsline),
        markersize=data.markersize,
        markeropacity=0.4,
        markerstrokewidth=0,
        lims=(x1, x2),
        color=:red,
        label="on line",
        ratio=1,
        dpi=600,
        title=title,
    )

    # save final plots
    savefig(pltcombined, "output/$title-combined.png")
    savefig(pltpos, "output/$title-pos.png")
    savefig(pltneg, "output/$title-neg.png")
    savefig(pltline, "output/$title-line.png")
end

# plot epsilon vs number of points where abs(det) < epsilon
function plotepsilon(data::Dataset{T}, es::AbstractRange{T}) where T
    title = "evclass-$(data.name)-$T-3x3-builtin"
    println(title)

    orientation(e, p) = pointorientationdet3x3(det, e, p, data.line)

    ys = map(es) do e
        os = map(p -> orientation(e, p), data.pnts)
        online = filter(x -> x==0, os)
        length(online)
    end

    plt = plot(es, ys,
        xlabel="epsilon",
        ylabel="points",
        legend=false,
        title=title,
    )
    savefig(plt, "output/$title.png")
end

# scatter points which were classified differently
function plotcomparison(d::Dataset{T}, c1::AlgoConfig, c2::AlgoConfig) where T
    title = "comp-$(d.name)-$(c1.orient)-$(c1.det)-$(c1.e)-vs-$(c2.orient)-$(c2.det)-$(c2.e)"
    println(title)

    # get area bounds
    x1 = minimum(getfield.(d.pnts, :x))
    x2 = maximum(getfield.(d.pnts, :x))

    classes1 = map(p -> c1.orientfn(p, d.line), d.pnts)
    classes2 = map(p -> c2.orientfn(p, d.line), d.pnts)
    pnts = getfield.(filter(collect(zip(d.pnts, classes1, classes2))) do x
        x[2] != x[3]
    end, 1)
    
    plt = scatter(
        Tuple.(pnts),
        markersize=d.markersize,
        markeropacity=0.4,
        markerstrokewidth=0,
        lims=(x1, x2),
        color=:red,
        label=false,
        ratio=1,
        dpi=600,
        title=title,
    )

    savefig(plt, "output/$title.png")
end

function main()
    U = Float64
    Ts = [Float32, Float64]
    
    datagens = [
        gendataseta,
        gendatasetb,
        gendatasetc,
        gendatasetd,
    ]

    datasets::Vector{Dataset{U}} = map(g -> g(U), datagens)

    for d in datasets
        for T in Ts
            plotclassification(convertdataset(T, d))
        end
    end

    for d in datasets
        plotepsilon(d, range(d.emin, d.emax, length=30))
    end

    plotcomparison(
        datasets[1],
        AlgoConfig(
            datasets[1].e,
            (p, l) -> pointorientationdet3x3(det, datasets[1].e, p, l),
            "builtin",
            "3x3"
        ),
        AlgoConfig(
            datasets[1].e*1.2,
            (p, l) -> pointorientationdet3x3(det, datasets[1].e*1.2, p, l),
            "builtin",
            "3x3"
        )
    )

    nothing
end

end # module
