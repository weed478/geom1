module AnalysisHelpers

export AlgoConfig,
       manualdet,
       findepsrange,
       findeps,
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

function findepsrange(d::Dataset{T})::Tuple{T, T} where T
    orient(e::T, p::Point{T}) = orient3x3(det, e, d.line, p)
    countpoints(e::T) = count(p -> orient(e, p) == 0, d.pnts)
    
    npnts = length(d.pnts)

    e::T = one(T)
    emax::T = e
    emin::T = e
    
    if (countpoints(e) >= npnts)
        while countpoints(emin) > 0
            emin /= 10
        end
        emax = nextfloat(emin)
        while countpoints(emax) < npnts
            emax *= 10
        end
        emin/10, emax*10
    else
        while countpoints(emax) < npnts
            emax *= 10
        end
        emin = prevfloat(emax)
        while countpoints(emin) > 0
            emin /= 10
        end
        emin/10, emax*10
    end
end

function findeps(d::Dataset{T}, npnts::Integer, error::Integer)::T where T
    emin, emax = findepsrange(d)
    findeps(d, npnts, error, emin, emax)
end

function findeps(d::Dataset{T}, npnts::Integer, error::Integer, emin::T, emax::T)::T where T
    orient(e::T, p::Point{T}) = orient3x3(det, e, d.line, p)
    countpoints(e::T) = count(p -> orient(e, p) == 0, d.pnts)
    
    e::T = (emin+emax)/2
    
    while true
        e = (emin+emax)/2
        n = countpoints(e)
        if n < npnts - error
            if emin == e
                e = emax
                break
            end
            emin = e
        elseif n > npnts + error
            if emax == e
                e = emin
            end
            emax = e
        else
            break
        end
    end

    while countpoints(e) < npnts - error
        e = nextfloat(e)
    end

    e
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

    # get area left/right bounds
    x1 = minimum(getfield.(pnts, :x))
    x2 = maximum(getfield.(pnts, :x))

    # move points away from eachother
    x1 += T(.1) * (x1 - x2)
    x2 += T(.1) * (x2 - x1)

    # plot with all points (colors representing classes) and the line used for classification
    plot(
        ratio=1,
        title=title,
        lims=(x1, x2),
    )

    scatter!(
        Tuple.(pntsneg),
        color=:black,
        label="neg",
        markersize=data.markersize,
        markerstrokewidth=0,
    )

    scatter!(
        Tuple.(pntspos),
        color=:gray,
        label="pos",
        markersize=data.markersize,
        markerstrokewidth=0,
    )

    scatter!(
        Tuple.(pntsline),
        color=:red,
        label="on line",
        markersize=data.linemarkersize,
        markerstrokewidth=0,
    )

    savefig("output/$title-1combined.png")

    # plots with individual classes

    scatter(
        Tuple.(pntsline),
        color=:red,
        label="on line",
        markersize=data.linemarkersize,
        markerstrokewidth=0,
        lims=(x1, x2),
        ratio=1,
        title=title,
    )

    savefig("output/$title-2line.png")

    scatter(
        Tuple.(pntsneg),
        color=:black,
        label="neg",
        markersize=data.markersize,
        markerstrokewidth=0,
        lims=(x1, x2),
        ratio=1,
        title=title,
    )

    savefig("output/$title-3neg.png")

    scatter(
        Tuple.(pntspos),
        color=:gray,
        label="pos",
        markersize=data.markersize,
        markerstrokewidth=0,
        lims=(x1, x2),
        ratio=1,
        title=title,
    )

    savefig("output/$title-4pos.png")
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
        markersize=d.linemarkersize,
        markeropacity=1.0,
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
