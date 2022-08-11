# A belt segment is some section of a belt, delineated by lines of contact with pulleys
# A free belt segment is a free section of belt beginning and ending at a pulley tangent point.  It is assumed straight and loaded only in tension. 
# An engaged belt segment is nominally in contact with some pulley

abstract type AbstractBelt end
abstract type AbstractSegment end

struct Route
  routing::Vector{T} where T<:AbstractSegment
end


"""
    printRoute(route::Vector{AbstractPulley})
  Prints the Pulleys and total belt length for the given `route`.
"""
function printRoute(route::Vector{T}) where T<:AbstractPulley
  for r in route #r is pulleys
    println(pulley2String(r))
  end
  # lTotal = calculateBeltLength(route)
  # println("total belt length = $lTotal") #No knowledge of the belt pitch, so can't list the correct belt
end

"""
    printSegments(segments::Vector{FreeSegment})
  Prints the Segments, and total belt length for the given `route`.
"""
function printSegments(segments::Vector{T}) where T<:AbstractSegment
  for s in segments
    println(toStringPoints(s))
  end
  # lTotal = calculateBeltLength(segments)
  # println("total belt length = $lTotal") #No knowledge of the belt pitch, so can't list the correct belt
end


# function calculateFreeLengths(segments::Vector{T}) where T<:AbstractSegment
# end
# function calculateTransmissionRatios(segments::Vector{T}) where T<:AbstractSegment
# end