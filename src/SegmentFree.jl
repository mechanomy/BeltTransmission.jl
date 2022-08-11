export FreeSegment, getDeparturePoint, getArrivalPoint, distance, findTangents, isSegmentMutuallyTangent, calculateRouteAngles, route2Segments, calculateBeltLength, toString, toStringShort, toStringPoints, printRoute, printSegments, length

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
@kwmethod FreeSegment(; depart::T, arrive::U) where {T<:AbstractPulley, U<:AbstractPulley} = FreeSegment(depart,arrive) #permit pulley types to differ


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
    FreeSegment: depart[E] [-0.013m, 0.012m] --> arrive[A] [0.110m, 0.083m] l[0.142m]@[29.973°]
"""
function toStringPoints(seg::FreeSegment) :: String
  pdep = getDeparturePoint(seg)
  un = unit(pdep.x)
  dstr = @sprintf("depart[%s] [%3.3f%s, %3.3f%s]",
    seg.depart.name,
    ustrip(un, pdep.x), string(un),
    ustrip(un, pdep.y), string(un)
  )

  parr = getArrivalPoint(seg)
  astr = @sprintf("arrive[%s] [%3.3f%s, %3.3f%s]",
    seg.arrive.name,
    ustrip(un, parr.x), string(un),
    ustrip(un, parr.y), string(un)
  )

  lda = norm(parr-pdep)
  ada = Geometry2D.angle(parr-pdep)
  lstr = @sprintf(" l[%3.3f%s]@[%3.3f°]", ustrip(un,lda), string(un), ustrip(u"°",ada))

  str = "FreeSegment: " * dstr * " --> " * astr * lstr
  return str
end

