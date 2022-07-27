# A belt segment is a free section of belt beginning and ending at a pulley tangent point.  It is assumed straight and loaded only in tension. 

export Segment, getDeparturePoint, getArrivalPoint, distance, findTangents, isSegmentMutuallyTangent, calculateRouteAngles, route2Segments, calculateBeltLength, toString, toStringShort, toStringPoints, toStringVectors, printRoute, printSegments, length


"""
Describes a belt segment between `depart` and `arrive` Pulleys.
$FIELDS
"""
struct Segment #this should set aArrive & aDepart on the pulleys...mutable pulley?
  """Departing Pulley"""
  depart::Pulley #expanded to the Point on the `pitch` circle at `aDepart`
  """Arriving Pulley"""
  arrive::Pulley #expanded to the Point on the `pitch` circle at `aArrive`
end
@kwdispatch Segment()

"""
    Segment(; depart::Pulley, arrive::Pulley) :: Segment
Create a belt Segment between `depart` and `arrive` Pulleys
"""
@kwmethod Segment(; depart::Pulley, arrive::Pulley) = Segment(depart,arrive)

"""
    plotRecipe(seg::Segment; n=100, lengthUnit=u"mm", segmentColor=:magenta, arrowFactor=0.03)
Plot recipe to plot the free sections of a segment, does not plot the pulleys.
```
using Plots, Unitful, BeltTransmission, Geometry2D
a = Pulley( Geometry2D.Circle(1u"mm",2u"mm",3u"mm"), Geometry2D.uk, "recipe" )
b = Pulley( Geometry2D.Circle(10u"mm",2u"mm",3u"mm"), Geometry2D.uk, "recipe" )
seg = Segment(depart=a, arrive=b)
plot(seg)
```
"""
@recipe function plotRecipe(seg::Segment; n=100, lengthUnit=u"mm", segmentColor=:magenta, arrowFactor=0.03)
  pd = getDeparturePoint( seg )
  pa = getArrivalPoint( seg )
  x = LinRange( pd.x, pa.x, n )
  y = LinRange( pd.y, pa.y, n )

  seriestype := :path 
  linecolor --> segmentColor
  linewidth --> 3 #would like this to be 3x default...above lwd is ":auto" not a number when this runs...
  aspect_ratio := :equal 
  label --> toString(seg)
  legend_background_color --> :transparent
  legend_position --> :outerright

  ustrip.(lengthUnit,x), ustrip.(lengthUnit,y) #return the data
end

"""
    plotRecipe(route::Vector{Pulley})
Plots the Pulleys in a `route`.
```
using Plots, Unitful, BeltTransmission, Geometry2D
a = Pulley( Geometry2D.Circle(1u"mm",2u"mm",3u"mm"), Geometry2D.uk, "recipe" )
b = Pulley( Geometry2D.Circle(10u"mm",2u"mm",3u"mm"), Geometry2D.uk, "recipe" )
route = calculateRouteAngles([a,b])
plot(route)
```
"""
@recipe function plotRecipe(route::Vector{Pulley})
  nr = length(route)

  #plot segments first, behind pulleys
  for ir in 1:nr
    @series begin
      Segment( depart=route[ir], arrive=route[Utility.iNext(ir,nr)] )
    end
  end

  #plot pulleys
  for ir in 1:nr
    @series begin
      route[ir] #route[ir] is returned to _ to be plotted
    end
  end
end

"""
    plotRecipe(segments::Vector{Segment})
Plots the Pulleys and Segments in a `route`.
```
using Plots, Unitful, BeltTransmission, Geometry2D
a = Pulley( Geometry2D.Circle(1u"mm",2u"mm",3u"mm"), Geometry2D.uk, "recipe" )
b = Pulley( Geometry2D.Circle(10u"mm",2u"mm",3u"mm"), Geometry2D.uk, "recipe" )
route = calculateRouteAngles([a,b])
segments = route2Segments(route)
plot(segments)
```
"""
@recipe function plotRecipe(segments::Vector{Segment})
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
    Base.show(io::IO, seg::Segment)
show()s the Segment via [`toStringShort`](@ref).
"""
function Base.show(io::IO, seg::Segment)
  println(toStringShort(seg))
end

"""
    getDeparturePoint(seg::Segment) :: Geometry2D.Point
Returns the departure Geometry2D.Point of `seg`.
"""
function getDeparturePoint(seg::Segment)
  getDeparturePoint(seg.depart)
end

"""
    getArrivalPoint(seg::Segment) :: Geometry2D.Point
Returns the arrival Geometry2D.Point of `seg`.
"""
function getArrivalPoint(seg::Segment)
  getArrivalPoint(seg.arrive) 
end



# Both Geometry2D and BeltTransmission export a method distance(), leading to a collision even though they are differentiated by type, as https://discourse.julialang.org/t/two-modules-with-the-same-exported-function-name-but-different-signature/15231/13
"""
    distance(seg::Segment) :: Unitful.Length
Returns the straight-line distance or length of Segment `seg`.
"""
function distance(seg::Segment) :: Unitful.Length
  return Geometry2D.distance( getDeparturePoint(seg), getArrivalPoint(seg) )
end

import Base.length
"""
    Base.length(seg::Segment) :: Unitful.Length
Returns the straight-line distance or length of Segment `seg` via [`distance`](@ref).
"""
function Base.length(seg::Segment) :: Unitful.Length
  return distance(seg)
end


"""
    findTangents(; a::Pulley, b::Pulley, plotResult::Bool=false) :: Vector{Segment}
Find four lines tangent to both Pulley `a` and `b`, returns 4 Segments with departure and arrival angles locating the points of tangency on the circles.
"""
function findTangents(seg::Segment) :: Vector{Segment}
  lCenter = Geometry2D.distance( seg.depart.pitch.center, seg.arrive.pitch.center )

  #ensure that pulleys are not coincident...this would manifest more clearly in aCross/aPara...
  if lCenter < 0.001mm
    segstr = toStringShort(seg) #call toStringShort() here so that the result is ready and able to be caught by the testthrows, otherwise a random "A--A" shows up
    throw( DomainError(lCenter, "findTangents: pulleys on Segment[$segstr] are coincident, can't find tangents") )
    return false
  end

  aCenter = Geometry2D.angle( seg.arrive.pitch.center-seg.depart.pitch.center ) # the angle of the relative vector between the pulley centers == the angle of the centerline

  aCross = acos( (seg.depart.pitch.radius+seg.arrive.pitch.radius) / lCenter ) #angle of the center-crossing rays, this triangle looks like: hypotenuse=lCenter, adjacent=a.r+b.r, giving the angle between the hyp/centerline and the radial vector perpendicular to the line of tangency
  aPara = acos( (seg.depart.pitch.radius-seg.arrive.pitch.radius) / lCenter ) #angle of the rays that don't cross the centerline

  #four angles departing A
  a1 = Geometry2D.angleWrap( aCenter+aPara )
  a2 = Geometry2D.angleWrap( aCenter-aPara )
  a3 = Geometry2D.angleWrap( aCenter+aCross )
  a4 = Geometry2D.angleWrap( aCenter-aCross )

  #four complimentary angles arriving at B
  b1 = Geometry2D.angleWrap( aCenter+aPara )
  b2 = Geometry2D.angleWrap( aCenter-aPara )
  b3 = Geometry2D.angleWrap( -(pi-aCenter-aCross) )
  b4 = Geometry2D.angleWrap( pi+aCenter-aCross )

  #                       old circle        newly found tangent angle  old: 
  depart1 = Pulley(circle=seg.depart.pitch, aDepart=a1*u"rad",         aArrive=seg.depart.aArrive, axis=seg.depart.axis, name=seg.depart.name)
  depart2 = Pulley(circle=seg.depart.pitch, aDepart=a2*u"rad",         aArrive=seg.depart.aArrive, axis=seg.depart.axis, name=seg.depart.name)
  depart3 = Pulley(circle=seg.depart.pitch, aDepart=a3*u"rad",         aArrive=seg.depart.aArrive, axis=seg.depart.axis, name=seg.depart.name)
  depart4 = Pulley(circle=seg.depart.pitch, aDepart=a4*u"rad",         aArrive=seg.depart.aArrive, axis=seg.depart.axis, name=seg.depart.name)

  arrive1 = Pulley(circle=seg.arrive.pitch, aArrive=b1*u"rad",         aDepart=seg.arrive.aDepart, axis=seg.arrive.axis, name=seg.arrive.name)
  arrive2 = Pulley(circle=seg.arrive.pitch, aArrive=b2*u"rad",         aDepart=seg.arrive.aDepart, axis=seg.arrive.axis, name=seg.arrive.name)
  arrive3 = Pulley(circle=seg.arrive.pitch, aArrive=b3*u"rad",         aDepart=seg.arrive.aDepart, axis=seg.arrive.axis, name=seg.arrive.name)
  arrive4 = Pulley(circle=seg.arrive.pitch, aArrive=b4*u"rad",         aDepart=seg.arrive.aDepart, axis=seg.arrive.axis, name=seg.arrive.name)
  ret = [Segment(depart=depart1, arrive=arrive1),Segment(depart=depart2, arrive=arrive2),Segment(depart=depart3, arrive=arrive3),Segment(depart=depart4, arrive=arrive4)]
  return ret
end 

"""
    isSegmentMutuallyTangent( seg::Segment ) :: Bool
Determines whether the departure and arrival points are tangent to the connecting belt segment.

For a segment a->b between ai&bi; the correct arrival and departure angles will have cross products that match both axes, 
 (ra-a1)x(a1-b1) = ax1 && (rb-b1)x(a1-b1) = bx1, all others should be false.
"""
function isSegmentMutuallyTangent( seg::Segment ) :: Bool
 #versus Geometry2D.isSegmentMutuallyTangent(), this compares the cross product to the pulley axis to test that the cross is in the same direction as the pulley's positive roatation

  a =   seg.depart
  thA = seg.depart.aDepart
  b =   seg.arrive
  thB = seg.arrive.aArrive
  
  raa4 = a.pitch.radius * [cos(thA), sin(thA),0]
  rbb4 = b.pitch.radius * [cos(thB), sin(thB),0]
  a4b4 = ([b.pitch.center.x,b.pitch.center.y,0u"mm"]+rbb4) - ([a.pitch.center.x,a.pitch.center.y,0u"mm"]+raa4) #difference between tangent points, a to b, defines the belt segment

  uraa4 = normalize(ustrip.(u"mm",raa4)) #normalization cancels units
  urbb4 = normalize(ustrip.(u"mm", rbb4) )
  ua4b4 = normalize(ustrip.(u"mm", a4b4) )
  ca4 = cross(uraa4, ua4b4)
  cb4 = cross(urbb4, ua4b4)
  da4 = dot(ca4, Geometry2D.toVector(a.axis) )
  db4 = dot(cb4, Geometry2D.toVector(b.axis) )
  return isapprox(da4, 1, rtol=1e-3) && isapprox(db4, 1, rtol=1e-3)
end

"""
    calculateRouteAngles(route::Vector{Pulley}, plotSegments::Bool=false) :: Vector{Pulley}
Given an ordered vector of Pulleys, output a vector of new Pulleys whose aArrive and aDepart angles are set to connect the pulleys with mutually tangent segments.
Convention: pulleys are listed in 'positive' belt rotation order, consistent with the direction of each Pulley's rotation axis.
"""
function calculateRouteAngles(route::Vector{Pulley})::Vector{Pulley}
  nr = size(route,1)
  solved = route #allocate the array

  for ir in 1:1:nr
    a = route[ir]
    b = route[Utility.iNext(ir,nr)]
    segments = findTangents(Segment(depart=a, arrive=b))

    for ia in 1:4 # there are 4 angle solutions in angles
      if isSegmentMutuallyTangent( segments[ia] )
        solved[ir]                   = segments[ia].depart #assigns ir to the depart pulley, which already has .arrive from ir-1
        solved[Utility.iNext(ir,nr)] = segments[ia].arrive 
      end
    end
  end
  return solved
end

"""
    route2Segments(route::Vector{Pulley}) :: Vector{Segment}
Given the ordered Pulleys of a belt routing, returns a vector of the free-space Segments connecting the Pulleys.
"""
function route2Segments(route::Vector{Pulley}) :: Vector{Segment}
  nr = length(route) 
  segments = Vector{Segment}(undef, nr) # #pulleys == #segments
  for ir in 1:nr
    segments[ir] = Segment(depart=route[ir], arrive=route[Utility.iNext(ir,nr)])
  end
  return segments
end

"""
    calculateBeltLength(segments::Vector{Segment}) :: Unitful.Length
Calculates the belt length over the given `route` as the sum of straight Segments.
"""
function calculateBeltLength(segments::Vector{Segment}) :: Unitful.Length
  l = 0u"mm"
  for seg in segments
    lwl = calculateWrappedLength(seg.depart) #only include one of the pulleys per iteration..assumes a closed belt
    ld = distance(seg)
    l += lwl + ld
  end

  #for open belts, add the missed pulley
  if segments[1].arrive != last(segments).depart
    l+= calculateWrappedLength(segments[1].arrive) 
  end
  return l
end

"""
    calculateBeltLength(route::Vector{Pulley}) :: Unitful.Length
Calculates the belt length over the given `route` as the sum of circular sections at the Pulley pitch radii between the arrival and departure angles.
"""
function calculateBeltLength(route::Vector{Pulley}) :: Unitful.Length
  return calculateBeltLength( route2Segments(route) ) 
end

"""
    toString(seg::Segment) :: String
Calls [`toStringShort`](@ref).
"""
function toString(seg::Segment) :: String
  return toStringShort(seg)
end

"""
    toStringShort(seg::Segment) :: String
Returns a short string of the form 'A -- B', for a departing Pulley named A arriving at a Pulley named B.
"""
function toStringShort(seg::Segment) :: String
  return "$(seg.depart.name)--$(seg.arrive.name)"
end

"""
    toStringPoints(seg::Segment) :: String
Creates strings like:
    Segment: depart[100.000, 110.000] -- arrive[-100.000, 110.000] length[200.000]
"""
function toStringPoints(seg::Segment) :: String
  pd = getDeparturePoint(seg)
  pa = getArrivalPoint(seg)
  un = unit(pd.x)
  str = @sprintf("Segment: depart[%3.3f, %3.3f] -- arrive[%3.3f, %3.3f] length[%3.3f]",
  ustrip(un, pd.x), ustrip(un, pd.y),
  ustrip(un, pa.x), ustrip(un, pa.y),
  ustrip(distance(seg) ) )
  return str
end

"""
    toStringVectors(seg::Segment) :: String
Creates strings like:
    "A:[100.000,100.000]<10.000@90.000°>[100.000,110.000]--B:[-100.000,100.000]<10.000@90.000°>[-100.000,110.000]"
"""
function toStringVectors(seg::Segment)
  # pd = getDepartureVector(seg)
  # pa = getArrivalVector(seg)

  pdct = seg.depart.pitch.center
  pdep = getDeparturePoint(seg)
  dvec = Geometry2D.Vector2D(origin=pdct, tip=pdep)
  un = unit(dvec.origin.x)
  dstr = @sprintf("%s:[%3.3f,%3.3f]<%3.3f@%3.3f°>[%3.3f,%3.3f]",
    seg.depart.name,
    ustrip(un,dvec.origin.x), ustrip(un,dvec.origin.y),
    ustrip(un, norm(dvec.tip-dvec.origin)), ustrip(°, Geometry2D.angle(dvec) ), 
    ustrip(un,dvec.tip.x), ustrip(un,dvec.tip.y) )

  pact = seg.arrive.pitch.center
  parr = getArrivalPoint(seg)
  avec = Geometry2D.Vector2D(origin=pact, tip=parr)
  astr = @sprintf("%s:[%3.3f,%3.3f]<%3.3f@%3.3f°>[%3.3f,%3.3f]",
    seg.arrive.name,
    ustrip(un,avec.origin.x), ustrip(un,avec.origin.y),
    ustrip(un, norm(avec.tip-avec.origin)), ustrip(°, Geometry2D.angle(avec) ), 
    ustrip(un,avec.tip.x), ustrip(un,avec.tip.y) )
  str = dstr * "--" * astr
  return str
end

"""
    printRoute(route::Vector{Pulley})
Prints the Pulleys and total belt length for the given `route`.
"""
function printRoute(route::Vector{Pulley})
  for r in route #r is pulleys
    println(pulley2String(r))
  end
  lTotal = calculateBeltLength(route)
  println("total belt length = $lTotal") #No knowledge of the belt pitch, so can't list the correct belt
end

"""
    printSegments(segments::Vector{Segment})
Prints the Segments, and total belt length for the given `route`.
"""
function printSegments(segments::Vector{Segment})
  for s in segments
    println(toStringVectors(s))
  end
  lTotal = calculateBeltLength(segments)
  println("total belt length = $lTotal") #No knowledge of the belt pitch, so can't list the correct belt
end

