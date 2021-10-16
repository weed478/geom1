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
    pnts::Vector{Point{T}}
    line::Segment{T}
    # plot parameters
    etyp::T
    emin::T
    emax::T
    markersize::Integer
end

function convertdataset(T::Type, d::Dataset)::Dataset{T}
    Dataset{T}(
        d.name,
        map(d.pnts) do p
            Point{T}(p.x, p.y)
        end,
        Segment{T}(
            Point{T}(d.line.A.x, d.line.A.y),
            Point{T}(d.line.B.x, d.line.B.y)
        ),
        T(d.etyp),
        T(d.emin),
        T(d.emax),
        d.markersize
    )
end

# generate n random numbers in range [lo,hi]
function uniformrandom(n::Integer, lo::T, hi::T)::Vector{T} where T
    rand(T, n) * (hi - lo) .+ lo
end

# create n points inside rect
function genpoints(rect::Rect{T}, n::Integer)::Vector{Point{T}} where T
    # unpack area coords
    xlo = rect.A.x
    xhi = rect.B.x
    ylo = rect.A.y
    yhi = rect.B.y

    # generate n random coords in range [xlo, xhi], [ylo, yhi]
    xs = uniformrandom(n, xlo, xhi)
    ys = uniformrandom(n, ylo, yhi)

    Point.(zip(xs, ys)) |> collect
end

# create n points on circle border
function genpoints(circ::Circle{T}, n::Integer)::Vector{Point{T}} where T
    r = circ.r
    x0, y0 = Tuple(circ.O)

    # random angles
    phis = uniformrandom(n, 0.f0, 2.f0pi)
    
    # gen coords
    xs = x0 .+ r * cos.(phis)
    ys = y0 .+ r * sin.(phis)

    Point.(zip(xs, ys)) |> collect
end

gendataseta(T::Type)::Dataset{T} = Dataset{T}(
    "A",
    genpoints(
        Rect(Point{T}(-1000, -1000), Point{T}(1000, 1000)),
        10^5
    ),
    Segment{T}(
        Point{T}(-1, 0),
        Point{T}(1, .1)
    ),
    T(100),
    T(0),
    T(200),
    1
)

gendatasetb(T::Type)::Dataset{T} = Dataset{T}(
    "B",
    genpoints(
        Rect(Point{T}(-10^14, -10^14), Point{T}(10^14, 10^14)),
        10^5
    ),
    Segment{T}(
        Point{T}(-1, 0),
        Point{T}(1, .1)
    ),
    T(10e12),
    T(1e12),
    T(20e12),
    1
)

gendatasetc(T::Type)::Dataset{T} = Dataset{T}(
    "C",
    genpoints(
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
    2
)

function gendatasetd(T::Type)::Dataset{T}
    # gen X coords
    xs = uniformrandom(1000, T(-1000), T(1000))

    A = Point{T}(-1, 0)
    B = Point{T}(1, .1)

    # calculate line equation
    f = tofunction(Segment(A, B))

    Dataset(
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
        2
    )
end

end # module
