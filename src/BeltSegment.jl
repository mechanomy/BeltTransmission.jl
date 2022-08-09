# A belt segment is some section of a belt, delineated by lines of contact with pulleys
# A free belt segment is a free section of belt beginning and ending at a pulley tangent point.  It is assumed straight and loaded only in tension. 
# An engaged belt segment is nominally in contact with some pulley

abstract type AbstractBelt end
abstract type AbstractSegment end

struct Route
  routing::Vector{T} where T<:AbstractSegment
end

"""
    plotRecipe(segments::Vector{T}) where T<:AbstractSegment
  Plots the Pulleys and Segments in a `route`.
  ```
  using Plots, Unitful, BeltTransmission, Geometry2D
  a = PlainPulley( Geometry2D.Circle(1u"mm",2u"mm",3u"mm"), Geometry2D.uk, "recipe" )
  b = PlainPulley( Geometry2D.Circle(10u"mm",2u"mm",3u"mm"), Geometry2D.uk, "recipe" )
  route = calculateRouteAngles([a,b])
  segments = route2Segments(route)
  plot(segments)
  ```
"""
@recipe function plotRecipe(segments::Vector{T}) where T<:AbstractSegment
  #plot segments first, behind pulleys
  for seg in segments
    @series begin
      seg
    end
  end

  nr = length(segments)
  #plot pulleys
  for ir in 1:nr
    @series begin
      segments[ir].depart #route[ir] is returned to _ to be plotted
    end
  end
  #for open belts, add the missed pulley
  if segments[1].arrive != last(segments).depart
    segments[1].arrive 
  end
end


"""
    printRoute(route::Vector{AbstractPulley})
  Prints the Pulleys and total belt length for the given `route`.
"""
function printRoute(route::Vector{T}) where T<:AbstractPulley
  for r in route #r is pulleys
    println(pulley2String(r))
  end
  lTotal = calculateBeltLength(route)
  println("total belt length = $lTotal") #No knowledge of the belt pitch, so can't list the correct belt
end

"""
    printSegments(segments::Vector{FreeSegment})
  Prints the Segments, and total belt length for the given `route`.
"""
function printSegments(segments::Vector{T}) where T<:AbstractSegment
  for s in segments
    println(toStringVectors(s))
  end
  lTotal = calculateBeltLength(segments)
  println("total belt length = $lTotal") #No knowledge of the belt pitch, so can't list the correct belt
end

