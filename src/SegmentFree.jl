export FreeSegment, getDeparturePoint, getArrivalPoint, distance, findTangents, isSegmentMutuallyTangent, calculateRouteAngles, route2Segments, calculateBeltLength, toString, toStringShort, toStringPoints, toStringVectors, printRoute, printSegments, length

"""
  Subtypes of AbstractFreeSegment model free belt segments beginning at the `depart`ure point traveling towards the `arrive` point under postive motion.
"""
abstract type AbstractFreeSegment <: AbstractSegment end

"""
  Describes a belt segment between `depart` and `arrive` Pulleys.
  $FIELDS
"""
struct FreeSegment <: AbstractFreeSegment #this should set arrive & depart on the pulleys...mutable pulley?
  """Departing pulley"""
  depart::AbstractPulley #expanded to the Point on the `pitch` circle at `depart`

  """Arriving pulley"""
  arrive::AbstractPulley #expanded to the Point on the `pitch` circle at `arrive`
end
@kwdispatch FreeSegment()

"""
    FreeSegment(; depart::AbstractPulley, arrive::AbstractPulley) :: FreeSegment
  Create a belt FreeSegment between `depart` and `arrive` Pulleys
"""
# @kwmethod FreeSegment(; depart::T, arrive::T) where T<:AbstractPulley = FreeSegment(depart,arrive)
@kwmethod FreeSegment(; depart::T, arrive::U) where {T<:AbstractPulley, U<:AbstractPulley} = FreeSegment(depart,arrive)


"""
    plotRecipe(seg::FreeSegment; n=100, lengthUnit=u"mm", segmentColor=:magenta, arrowFactor=0.03)
  Plot recipe to plot the free sections of a segment, does not plot the pulleys.
  ```
  using Plots, Unitful, BeltTransmission, Geometry2D
  a = PlainPulley( Geometry2D.Circle(1u"mm",2u"mm",3u"mm"), Geometry2D.uk, "recipe" )
  b = PlainPulley( Geometry2D.Circle(10u"mm",2u"mm",3u"mm"), Geometry2D.uk, "recipe" )
  seg = FreeSegment(depart=a, arrive=b)
  plot(seg)
  ```
"""
@recipe function plotRecipe(seg::FreeSegment; n=100, lengthUnit=u"mm", segmentColor=:magenta, arrowFactor=0.03)
  println("prFreeSegment")
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
    Base.show(io::IO, seg::FreeSegment)
  show()s the FreeSegment via [`toStringShort`](#BeltTransmission.toStringShort).
"""
function Base.show(io::IO, seg::FreeSegment)
  println(toStringShort(seg))
end

"""
    getDeparturePoint(seg::FreeSegment) :: Geometry2D.Point
  Returns the departure Geometry2D.Point of `seg`.
"""
function getDeparturePoint(seg::FreeSegment)
  getDeparturePoint(seg.depart)
end

"""
    getArrivalPoint(seg::FreeSegment) :: Geometry2D.Point
  Returns the arrival Geometry2D.Point of `seg`.
"""
function getArrivalPoint(seg::FreeSegment)
  getArrivalPoint(seg.arrive) 
end

# Both Geometry2D and BeltTransmission export a method distance(), leading to a collision even though they are differentiated by type, as https://discourse.julialang.org/t/two-modules-with-the-same-exported-function-name-but-different-signature/15231/13
"""
    distance(seg::FreeSegment) :: Unitful.Length
  Returns the straight-line distance or length of FreeSegment `seg`.
"""
function Geometry2D.distance(seg::FreeSegment) :: Unitful.Length
  return Geometry2D.distance( getDeparturePoint(seg), getArrivalPoint(seg) )
end

import Base.length
"""
    Base.length(seg::FreeSegment) :: Unitful.Length
  Returns the straight-line distance or length of FreeSegment `seg` via [`distance`](#BeltTransmission.distance).
"""
function Base.length(seg::FreeSegment) :: Unitful.Length
  return distance(seg)
end


"""
    findTangents(seg::FreeSegment) :: Vector{FreeSegment}
  Find four lines tangent to both pulleys `a` and `b`, returns 4 Segments with departure and arrival angles locating the points of tangency on the circles.
"""
function findTangents(seg::FreeSegment) :: Vector{FreeSegment}
  lCenter = Geometry2D.distance( seg.depart.pitch.center, seg.arrive.pitch.center )

  #ensure that pulleys are not coincident...this would manifest more clearly in aCross/aPara...
  if lCenter < 0.001mm
    segstr = toStringShort(seg) #call toStringShort() here so that the result is ready and able to be caught by the testthrows, otherwise a random "A--A" shows up
    throw( DomainError(lCenter, "findTangents: pulleys on FreeSegment[$segstr] are coincident, can't find tangents") )
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

  DType = typeof(seg.depart)
  depart1 = DType(seg.depart, seg.depart.arrive, a1*u"rad")
  depart2 = DType(seg.depart, seg.depart.arrive, a2*u"rad")
  depart3 = DType(seg.depart, seg.depart.arrive, a3*u"rad")
  depart4 = DType(seg.depart, seg.depart.arrive, a4*u"rad")

  AType = typeof(seg.arrive)
  arrive1 = AType(seg.arrive, b1*u"rad", seg.arrive.depart)
  arrive2 = AType(seg.arrive, b2*u"rad", seg.arrive.depart)
  arrive3 = AType(seg.arrive, b3*u"rad", seg.arrive.depart)
  arrive4 = AType(seg.arrive, b4*u"rad", seg.arrive.depart)

  ret = [FreeSegment(depart=depart1, arrive=arrive1),FreeSegment(depart=depart2, arrive=arrive2),FreeSegment(depart=depart3, arrive=arrive3),FreeSegment(depart=depart4, arrive=arrive4)]
  return ret
end 

"""
    isSegmentMutuallyTangent( seg::FreeSegment ) :: Bool
  Determines whether the departure and arrival points are tangent to the connecting belt segment.

  For a segment a->b between ai&bi; the correct arrival and departure angles will have cross products that match both axes, 
 (ra-a1)x(a1-b1) = ax1 && (rb-b1)x(a1-b1) = bx1, all others should be false.
"""
function isSegmentMutuallyTangent( seg::FreeSegment ) :: Bool
 #versus Geometry2D.isSegmentMutuallyTangent(), this compares the cross product to the pulley axis to test that the cross is in the same direction as the pulley's positive roatation

  a =   seg.depart
  thA = seg.depart.depart
  b =   seg.arrive
  thB = seg.arrive.arrive
  
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
    calculateRouteAngles(route::Vector{AbstractPulley}, plotSegments::Bool=false) :: Vector{AbstractPulley}
  Given an ordered vector of Pulleys, output a vector of new Pulleys whose arrive and depart angles are set to connect the pulleys with mutually tangent segments.
  Convention: pulleys are listed in 'positive' belt rotation order, consistent with the direction of each pulley's rotation axis.
"""
function calculateRouteAngles(route::Vector{T})::Vector{T} where T <: AbstractPulley
  nr = size(route,1)
  solved = route #allocate the array

  for ir in 1:1:nr
    a = route[ir]
    b = route[Utility.iNext(ir,nr)]
    segments = findTangents(FreeSegment(depart=a, arrive=b))

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
    route2Segments(route::Vector{AbstractPulley}) :: Vector{FreeSegment}
  Given the ordered Pulleys of a belt routing, returns a vector of the free-space Segments connecting the Pulleys.
"""
function route2Segments(route::Vector{T}) :: Vector{FreeSegment} where T<:AbstractPulley
  nr = length(route) 
  segments = Vector{FreeSegment}(undef, nr) # #pulleys == #segments
  for ir in 1:nr
    segments[ir] = FreeSegment(depart=route[ir], arrive=route[Utility.iNext(ir,nr)])
  end
  return segments
end

"""
    calculateBeltLength(segments::Vector{FreeSegment}) :: Unitful.Length
  Calculates the belt length over the given `route` as the sum of straight Segments.
"""
function calculateBeltLength(segments::Vector{FreeSegment}) :: Unitful.Length
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
    calculateBeltLength(route::Vector{AbstractPulley}) :: Unitful.Length
  Calculates the belt length over the given `route` as the sum of circular sections at the pulley pitch radii between the arrival and departure angles.
"""
function calculateBeltLength(route::Vector{T}) :: Unitful.Length where T<:AbstractPulley
  return calculateBeltLength( route2Segments(route) ) 
end

"""
    toString(seg::FreeSegment) :: String
  Calls [`toStringShort`](#BeltTransmission.toStringShort).
"""
function toString(seg::FreeSegment) :: String
  return toStringShort(seg)
end

"""
    toStringShort(seg::FreeSegment) :: String
  Returns a short string of the form 'A -- B', for a departing pulley named A arriving at a pulley named B.
"""
function toStringShort(seg::FreeSegment) :: String
  return "$(seg.depart.name)--$(seg.arrive.name)"
end

"""
    toStringPoints(seg::FreeSegment) :: String
  Creates strings like:
    FreeSegment: depart[100.000, 110.000] -- arrive[-100.000, 110.000] length[200.000]
"""
function toStringPoints(seg::FreeSegment) :: String
  pd = getDeparturePoint(seg)
  pa = getArrivalPoint(seg)
  un = unit(pd.x)
  str = @sprintf("FreeSegment: depart[%3.3f, %3.3f] -- arrive[%3.3f, %3.3f] length[%3.3f]",
  ustrip(un, pd.x), ustrip(un, pd.y),
  ustrip(un, pa.x), ustrip(un, pa.y),
  ustrip(distance(seg) ) )
  return str
end

"""
    toStringVectors(seg::FreeSegment) :: String
  Creates strings like:
    "A:[100.000,100.000]<10.000@90.000°>[100.000,110.000]--B:[-100.000,100.000]<10.000@90.000°>[-100.000,110.000]"
"""
function toStringVectors(seg::FreeSegment)
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
# @recipe function plotRecipe(segments::Vector{T}) where T<:FreeSegment
# @recipe function plotRecipe(segments::Vector{T}) where T<:AbstractPulley
  println("prVectorAbstractSegment")
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

@recipe function plotRecipe(pulleys::Vector{T}) where T<:AbstractPulley
  println("prVectorAbstractPulley: segments")
  #plot segments first, behind pulleys
  for p in pulleys
    @series begin
      p
    end
  end

  println("prVectorAbstractPulley: pulleys")
  nr = length(pulleys)
  #plot pulleys
  for ir in 1:nr
    @show pulleys[ir]
    @show pulleys[ir].depart
    @series begin
      pulleys[ir] #route[ir] is returned to _ to be plotted
    end
    # if typeof(segments[ir].depart) <: AbstractPulley
    #   @series begin
    #     segments[ir].depart #route[ir] is returned to _ to be plotted
    #   end
    # else
    #   @series begin
    #     segments[ir]
    #   end
    # end
  end
  # #for open belts, add the missed pulley
  # if pulleys[1].arrive != last(pulleys).depart
  #   pulleys[1]
  # end
end

