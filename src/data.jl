module Data

export Dataset,
       convertdataset,
       gendataseta,
       gendatasetb,
       gendatasetc,
       gendatasetd

using ..Geometry

struct Dataset{T}
    name::String
    pnts::AbstractVector{Point{T}}
    line::Segment{T}
    # plot parameters
    etyp::T
    emin::T
    emax::T
    markersize::Integer
    linemarkersize::Integer
end

Dataset(
    name::String,
    pnts::AbstractVector{Point{T}},
    line::Segment{T},
    etyp::T,
    emin::T,
    emax::T,
    markersize::Integer,
    linemarkersize::Integer
) where T = Dataset{T}(
    name,
    pnts,
    line,
    etyp,
    emin,
    emax,
    markersize,
    linemarkersize
)

Dataset(::Type{T}, d::Dataset{T}) where T = d
Dataset(::Type{T}, d::Dataset) where T = Dataset{T}(
    d.name,
    Point.(T, d.pnts),
    Segment(T, d.line),
    T(d.etyp),
    T(d.emin),
    T(d.emax),
    d.markersize,
    d.linemarkersize
)

# generate n random numbers in range [lo,hi]
function uniformrandom(::Type{T}, n::Integer, lo::T, hi::T)::Vector{T} where T
    rand(T, n) * (hi - lo) .+ lo
end

# create n points inside rect
function genpoints(::Type{T}, rect::Rect{T}, n::Integer)::Vector{Point{T}} where T
    # unpack area coords
    xlo = rect.A.x
    xhi = rect.B.x
    ylo = rect.A.y
    yhi = rect.B.y

    # generate n random coords in range [xlo, xhi], [ylo, yhi]
    xs = uniformrandom(T, n, xlo, xhi)
    ys = uniformrandom(T, n, ylo, yhi)

    Point.(zip(xs, ys)) |> collect
end

# create n points on circle border
function genpoints(::Type{T}, circ::Circle{T}, n::Integer)::Vector{Point{T}} where T
    r = circ.r
    x0, y0 = Tuple(circ.O)

    # random angles
    phis = uniformrandom(T, n, T(0), T(2pi))
    
    # gen coords
    xs = x0 .+ r * cos.(phis)
    ys = y0 .+ r * sin.(phis)

    Point.(zip(xs, ys)) |> collect
end

function gendataseta(::Type{T})::Dataset{T} where T
    Dataset{T}(
        "A",
        genpoints(
            T,
            Rect{T}(Point{T}(-1000, -1000), Point{T}(1000, 1000)),
            10^5
        ),
        Segment{T}(
            Point{T}(-1, 0),
            Point{T}(1, .1)
        ),
        T(100),
        T(0),
        T(200),
        1, # markersize
        4 # linemarkersize
    )
end

function gendatasetb(::Type{T})::Dataset{T} where T
    Dataset{T}(
        "B",
        genpoints(
            T,
            Rect{T}(Point{T}(-10^14, -10^14), Point{T}(10^14, 10^14)),
            10^5
        ),
        Segment{T}(
            Point{T}(-1, 0),
            Point{T}(1, .1)
        ),
        T(10e12),
        T(1e12),
        T(20e12),
        1, # markersize
        4 # linemarkersize
    )
end

function gendatasetc(::Type{T})::Dataset{T} where T
    Dataset{T}(
        "C",
        genpoints(
            T,
            Circle{T}(Point{T}(0, 0), 100),
            1000
        ),
        Segment{T}(
            Point{T}(-1, 0),
            Point{T}(1, .1)
        ),
        T(10),
        T(0),
        T(250),
        2, # markersize
        3 # linemarkersize
    )
end

function gendatasetd(::Type{T})::Dataset{T} where T
    # gen X coords
    xs = uniformrandom(T, 1000, T(-1000), T(1000))

    A = Point{T}(-1, 0)
    B = Point{T}(1, .1)

    # calculate line equation
    f = tofunction(Segment{T}(A, B))

    Dataset{T}(
        "D",
        # for each generated X calculate Y
        Point.(zip(xs, f.(xs))) |> collect,
        Segment{T}(
            Point{T}(-1, 0),
            Point{T}(1, .1)
        ),
        T(1e-15),
        T(0),
        T(2e-14),
        2, # markersize
        2 # linemarkersize
    )
end

end # module
