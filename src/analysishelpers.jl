module AnalysisHelpers

export AlgoConfig,
       manualdet,
       plotclassification,
       plotepsilon,
       plotcomparison

using ..Geometry
using ..Data

using LinearAlgebra: det
using Plots

const DPI = 500

# configuration for the classifier
struct AlgoConfig{T}
    orientfn
    detfn
    e::T
    name::String
end

function manualdet(M::Matrix{T})::T where T
    if size(M) == (2, 2)
        M[1,1] * M[2,2] - M[1,2] * M[2,1]
    elseif size(M) == (3, 3)
          M[1,1] * M[2,2] * M[3,3] + M[1,2] * M[2,3] * M[3,1] + M[1,3] * M[2,1] * M[3,2] - M[3,1] * M[2,2] * M[1,3] - M[3,2] * M[2,3] * M[1,1] - M[3,3] * M[2,1] * M[1,2]
    else
        error("Invalid matrix size $(size(M))")
    end
end

# scatter plot of points
function plotclassification(data::Dataset{T}, config::AlgoConfig{T}) where T
    pnts = data.pnts
    AB = data.line
    
    # point orientation vs AB
    orient(P::Point{T}) = config.orientfn(config.detfn, config.e, AB, P)

    title = "class-$(data.name)-$(config.name)"
    println(title)


    # split points into 3 vectors based on orientation

    pntsline = filter(pnts) do P
        orient(P) == 0
    end

    pntsneg = filter(pnts) do P
        orient(P) < 0
    end

    pntspos = filter(pnts) do P
        orient(P) > 0
    end

    # plot with all points (colors representing classes) and the line used for classification
    pltcombined = plot(
        ratio=1,
        dpi=DPI,
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

    # overlay the line

    # get area left/right bounds
    x1 = minimum(getfield.(pnts, :x))
    x2 = maximum(getfield.(pnts, :x))

    # move points away from eachother
    x1 += T(.1) * (x1 - x2)
    x2 += T(.1) * (x2 - x1)
    
    # draw line using 2 points
    f = tofunction(AB)
    plot!(pltcombined,
        [(x1, f(x1)), (x2, f(x2))],
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
        dpi=DPI,
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
        dpi=DPI,
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
        dpi=DPI,
        title=title,
    )

    # save final plots
    savefig(pltcombined, "output/$title-1combined.png")
    savefig(pltpos, "output/$title-3pos.png")
    savefig(pltneg, "output/$title-4neg.png")
    savefig(pltline, "output/$title-2line.png")
end

# plot epsilon vs number of points where abs(det) < epsilon
function plotepsilon(data::Dataset{T}, c::AlgoConfig{T}, es::AbstractRange{T}) where T
    title = "evclass-$(data.name)-$(c.name)"
    println(title)

    # epsilon and point
    orient(e::T, P::Point{T}) = c.orientfn(c.detfn, e, data.line, P)

    # X axis = epsilons
    # Y axis = number of points on line
    ys = map(es) do e
        # classify all points with current epsilon
        orients = map(p -> orient(e, p), data.pnts)
        # count on line
        filter(x -> x==0, orients) |> length
    end

    plt = plot(es, ys,
        xlabel="epsilon",
        ylabel="points",
        legend=false,
        title=title,
    )
    savefig(plt, "output/$title.png")
end

# show points which were classified differently
function plotcomparison(d::Dataset{T}, c1::AlgoConfig{U}, c2::AlgoConfig{V}) where {T, U, V}
    title = "comp-$(d.name)-$(c1.name)-vs-$(c2.name)"
    println(title)

    d1 = Dataset(U, d)
    d2 = Dataset(V, d)

    orient1(P::Point{U}) = c1.orientfn(c1.detfn, c1.e, d1.line, P)
    orient2(P::Point{V}) = c2.orientfn(c2.detfn, c2.e, d2.line, P)

    # get area left/right bounds
    x1 = minimum(getfield.(d.pnts, :x))
    x2 = maximum(getfield.(d.pnts, :x))

    interesting = map(1:length(d.pnts)) do i
        orient1(d1.pnts[i]) != orient2(d2.pnts[i])
    end

    pnts = d.pnts[filter(1:length(d.pnts)) do i
        interesting[i]
    end]
    
    plt = scatter(
        Tuple.(pnts),
        markersize=d.markersize,
        markeropacity=0.4,
        markerstrokewidth=0,
        lims=(x1, x2),
        color=:red,
        label=false,
        ratio=1,
        dpi=DPI,
        title=title,
    )

    savefig(plt, "output/$title.png")
end

end # module AnalysisHelpers
