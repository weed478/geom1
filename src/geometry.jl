module Geometry

export Point,
       Rect,
       Circle,
       Segment,
       tofunction,
       orient3x3,
       orient2x2

struct Point{T}
    x::T
    y::T
end

Point(x::T, y::T) where T = Point{T}(x, y)

# helpers to convert to/from tuple
Point(p::Tuple{T, T}) where T = Point{T}(p[1], p[2])
Tuple(p::Point) = (p.x, p.y)
Base.convert(::Type{Tuple{T, T}}, p::Point{T}) where T = (p.x, p.y)
Base.convert(::Type{Point{T}}, p::Tuple{T, T}) where T = Point{T}(p[1], p[2])

# rect between 2 points
struct Rect{T}
    A::Point{T}
    B::Point{T}
end

struct Circle{T}
    O::Point{T}
    r::T
end

# line between 2 points
struct Segment{T}
    A::Point{T}
    B::Point{T}
end

# convert segment to function f(x) = ax + b
# y = ax + b
# a = dy/dx
# b = y - ax
function tofunction(seg::Segment)
    a = (seg.B.y - seg.A.y) / (seg.B.x - seg.A.x)
    b = seg.A.y - a * seg.A.x
    x -> a*x + b
end

# orientation functions

function orient3x3(detfn, e::T, l::Segment{T}, A::Point{T})::Int where T
    a = l.A
    b = l.B
    c = A

    M = [a.x a.y 1
         b.x b.y 1
         c.x c.y 1]

    d = detfn(M)

    if abs(d) < e
        0
    elseif d < 0
        -1
    else
        1
    end
end

function orient2x2(detfn, e::T, l::Segment{T}, A::Point{T})::Int where T
    a = l.A
    b = l.B
    c = A

    M = [(a.x - c.x) (a.y - c.y)
         (b.x - c.x) (b.y - c.y)]

    d = detfn(M)

    if abs(d) < e
        0
    elseif d < 0
        -1
    else
        1
    end
end

end # module
