export FreeSegment, getDeparturePoint, getArrivalPoint, distance, findTangents, isSegmentMutuallyTangent, calculateRouteAngles, route2Segments, calculateBeltLength, toString, toStringShort, toStringPoints, printSegments, length

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

@testitem "FreeSegment constructors" begin
  using Geometry2D, UnitTypes
  uk = Geometry2D.UnitVector(0,0,1)
  #a square of pulleys, arranged ccw from quadrant1
  pA = PlainPulley( pitch=Geometry2D.Circle( MilliMeter(100), MilliMeter(100), MilliMeter(10)), axis=uk, name="A")
  pB = PlainPulley( pitch=Geometry2D.Circle(MilliMeter(-100), MilliMeter(100), MilliMeter(10)), axis=uk, name="B")
  pC = PlainPulley( pitch=Geometry2D.Circle(MilliMeter(-100),MilliMeter(-100), MilliMeter(43)), axis=uk, name="C")
  pD = PlainPulley( pitch=Geometry2D.Circle( MilliMeter(100),MilliMeter(-100), MilliMeter(14)), axis=uk, name="D") 
  pE = PlainPulley( pitch=Geometry2D.Circle( MilliMeter(80),MilliMeter(-200), MilliMeter(14)), axis=-uk, name="E") 
  route = [pA, pB, pC, pD, pE]

  sab = FreeSegment( pA, pB )
  # @test length(sab) == Geometry2D.distance(pB.pitch.center, pA.pitch.center)
  @test distance(sab) == Geometry2D.distance(pB.pitch.center, pA.pitch.center)

  sab = FreeSegment( depart=pA, arrive=pB)
  @test length(sab) == Geometry2D.distance(pB.pitch.center, pA.pitch.center)
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
    distance(seg::FreeSegment) :: AbstractLength
  Returns the straight-line distance or length of FreeSegment `seg`.
"""
function Geometry2D.distance(seg::FreeSegment) :: AbstractLength
  return Geometry2D.distance( getDeparturePoint(seg), getArrivalPoint(seg) )
end

import Base.length
"""
    Base.length(seg::FreeSegment) :: AbstractLength
  Returns the straight-line distance or length of FreeSegment `seg` via [`distance`](#BeltTransmission.distance).
"""
function Base.length(seg::FreeSegment) :: AbstractLength
  return distance(seg)
end


"""
    findTangents(seg::FreeSegment) :: Vector{FreeSegment}
  Find four lines tangent to both pulleys `a` and `b`, returns 4 Segments with departure and arrival angles locating the points of tangency on the circles.
"""
function findTangents(seg::FreeSegment) :: Vector{FreeSegment}
  lCenter = Geometry2D.distance( seg.depart.pitch.center, seg.arrive.pitch.center )

  #ensure that pulleys are not coincident...this would manifest more clearly in aCross/aPara...
  if lCenter < MilliMeter(1e-3)
    segstr = toStringShort(seg) #call toStringShort() here so that the result is ready and able to be caught by the testthrows, otherwise a random "A--A" shows up
    throw( DomainError(lCenter, "findTangents: pulleys on FreeSegment[$segstr] are coincident, can't find tangents") )
    return false
  end

  aCenter = Geometry2D.angleRadian( seg.arrive.pitch.center-seg.depart.pitch.center ) # the angle of the relative vector between the pulley centers == the angle of the centerline

  aCross = Radian(acos( toBaseFloat(seg.depart.pitch.radius+seg.arrive.pitch.radius) / toBaseFloat(lCenter) )) #angle of the center-crossing rays, this triangle looks like: hypotenuse=lCenter, adjacent=a.r+b.r, giving the angle between the hyp/centerline and the radial vector perpendicular to the line of tangency
  aPara = Radian(acos( toBaseFloat(seg.depart.pitch.radius-seg.arrive.pitch.radius) / toBaseFloat(lCenter) )) #angle of the rays that don't cross the centerline

  #four angles departing A
  a1 = Geometry2D.angleWrap( aCenter+aPara )
  a2 = Geometry2D.angleWrap( aCenter-aPara )
  a3 = Geometry2D.angleWrap( aCenter+aCross )
  a4 = Geometry2D.angleWrap( aCenter-aCross )

  #four complimentary angles arriving at B
  b1 = Geometry2D.angleWrap( aCenter+aPara )
  b2 = Geometry2D.angleWrap( aCenter-aPara )
  # b3 = Geometry2D.angleWrap( -(Radian(pi)-aCenter-aCross) )
  b3 = Geometry2D.angleWrap( aCenter+aCross-Radian(pi))
  b4 = Geometry2D.angleWrap( Radian(pi)+aCenter-aCross )

  # now make new pulleys on the different angles
  DType = typeof(seg.depart) # BeltTransmission.PlainPulley(), Synchronous
  depart1 = DType(seg.depart, seg.depart.arrive, a1)
  depart2 = DType(seg.depart, seg.depart.arrive, a2)
  depart3 = DType(seg.depart, seg.depart.arrive, a3)
  depart4 = DType(seg.depart, seg.depart.arrive, a4)

  AType = typeof(seg.arrive)
  arrive1 = AType(seg.arrive, b1, seg.arrive.depart)
  arrive2 = AType(seg.arrive, b2, seg.arrive.depart)
  arrive3 = AType(seg.arrive, b3, seg.arrive.depart)
  arrive4 = AType(seg.arrive, b4, seg.arrive.depart)

  ret = [FreeSegment(depart=depart1, arrive=arrive1),FreeSegment(depart=depart2, arrive=arrive2),FreeSegment(depart=depart3, arrive=arrive3),FreeSegment(depart=depart4, arrive=arrive4)]
  return ret
end 
@testitem "findTangents" begin
  using Geometry2D, UnitTypes
  uk = Geometry2D.UnitVector(0,0,1)
  #a square of pulleys, arranged ccw from quadrant1
  pA = PlainPulley( pitch=Geometry2D.Circle( MilliMeter(100), MilliMeter(100), MilliMeter(10)), axis=uk, name="A")
  pB = PlainPulley( pitch=Geometry2D.Circle(MilliMeter(-100), MilliMeter(100), MilliMeter(10)), axis=uk, name="B")
  pC = PlainPulley( pitch=Geometry2D.Circle(MilliMeter(-100),MilliMeter(-100), MilliMeter(43)), axis=uk, name="C")
  pD = PlainPulley( pitch=Geometry2D.Circle( MilliMeter(100),MilliMeter(-100), MilliMeter(14)), axis=uk, name="D") 
  pE = PlainPulley( pitch=Geometry2D.Circle( MilliMeter(80),MilliMeter(-200), MilliMeter(14)), axis=-uk, name="E") 
  route = [pA, pB, pC, pD, pE]

  saa = FreeSegment(depart=pA, arrive=pA)
  sab = FreeSegment(depart=pA, arrive=pB)
  sac = FreeSegment(depart=pA, arrive=pC)
  @test_throws DomainError findTangents(saa) #overlap, throws

  tans = findTangents(sab)
  for i=1:4
    @test Geometry2D.isSegmentMutuallyTangent(cA=tans[i].depart.pitch, thA=tans[i].depart.depart, cB=tans[i].arrive.pitch, thB=tans[i].arrive.arrive )
  end

  tans = findTangents(sac)
  for i=1:4
    @test Geometry2D.isSegmentMutuallyTangent(cA=tans[i].depart.pitch, thA=tans[i].depart.depart, cB=tans[i].arrive.pitch, thB=tans[i].arrive.arrive )
  end

end

"""
Returns a unit-less vector from some UnitType vector 
"""
function normalizeUnitless(a::Vector{T}) where T<:AbstractLength
  tt = typeof(a[1])
  nn = normalize( [toBaseFloat(a[1]), toBaseFloat(a[2]), toBaseFloat(a[3])] )
  # return [tt(nn[1]), tt(nn[2]), tt(nn[3])]  unit vectors are unitless...
  return nn
end
@testitem "normalizeUnitless" begin
  using UnitTypes
  n = BeltTransmission.normalizeUnitless([Meter(1),Meter(2),Meter(3)]) 
  @test n[1] ≈ 1/sqrt(1+4+9)
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
  
  raa4 = a.pitch.radius .* [cos(thA), sin(thA),0] # radial vector from a to point of departure
  rbb4 = b.pitch.radius .* [cos(thB), sin(thB),0] # radial vector from b to point of arrival
  a4b4 = ([b.pitch.center.x,b.pitch.center.y,MilliMeter(0)]+rbb4) - ([a.pitch.center.x,a.pitch.center.y,MilliMeter(0)]+raa4) #difference between tangent points, a to b, defines the belt segment

  uraa4 = normalizeUnitless(raa4) #normalization cancels units
  urbb4 = normalizeUnitless(rbb4)
  ua4b4 = normalizeUnitless(a4b4)
  ca4 = cross(uraa4, ua4b4)
  cb4 = cross(urbb4, ua4b4)
  da4 = dot(ca4, Geometry2D.toVector(a.axis) )
  db4 = dot(cb4, Geometry2D.toVector(b.axis) )
  return isapprox(da4, 1, rtol=1e-3) && isapprox(db4, 1, rtol=1e-3)
end
@testitem "isSegmentMutuallyTangent" begin
  using Geometry2D, UnitTypes
  uk = Geometry2D.UnitVector(0,0,1)
  pA = PlainPulley( pitch=Geometry2D.Circle( MilliMeter(100), MilliMeter(100), MilliMeter(10)), arrive=Degree(0), depart=Radian(π/2),               axis=uk, name="A")
  pB = PlainPulley( pitch=Geometry2D.Circle(MilliMeter(-100), MilliMeter(100), MilliMeter(10)),             arrive=Radian(π/2), depart=Degree(200), axis=uk, name="B")
  seg = FreeSegment( depart=pA, arrive=pB )
  @test BeltTransmission.isSegmentMutuallyTangent( seg )

  pA = PlainPulley( pitch=Geometry2D.Circle( MilliMeter(100), MilliMeter(100), MilliMeter(10)), arrive=Degree(0), depart=Degree(90),               axis=uk, name="A")
  pB = PlainPulley( pitch=Geometry2D.Circle(MilliMeter(-100), MilliMeter(100), MilliMeter(10)),             arrive=Degree(90), depart=Degree(200), axis=uk, name="B")
  seg = FreeSegment( depart=pA, arrive=pB )
  @test BeltTransmission.isSegmentMutuallyTangent( seg )
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
@testitem "calculateRouteAngles" begin
  using Geometry2D, UnitTypes
  uk = Geometry2D.UnitVector(0,0,1)
  #a square of pulleys, arranged ccw from quadrant1
  pA = PlainPulley( pitch=Geometry2D.Circle( MilliMeter(100), MilliMeter(100), MilliMeter(10)), axis=uk, name="A")
  pB = PlainPulley( pitch=Geometry2D.Circle(MilliMeter(-100), MilliMeter(100), MilliMeter(10)), axis=uk, name="B")
  pC = PlainPulley( pitch=Geometry2D.Circle(MilliMeter(-100),MilliMeter(-100), MilliMeter(43)), axis=uk, name="C")
  pD = PlainPulley( pitch=Geometry2D.Circle( MilliMeter(100),MilliMeter(-100), MilliMeter(14)), axis=uk, name="D") 
  pE = PlainPulley( pitch=Geometry2D.Circle( MilliMeter(80),MilliMeter(-200), MilliMeter(14)), axis=-uk, name="E") 
  route = [pA, pB, pC, pD, pE]

  solved = calculateRouteAngles(route)

  #test confirmed via plot, copying angles into below to guard changes
  # @test isapprox(solved[1].arrive, Radian(5.327), rtol=1e-3) # E@0,0
  @test isapprox(solved[1].arrive, Radian(6.136), rtol=1e-3) # E@80,-200
  @test isapprox(solved[2].arrive, Radian(1.571), rtol=1e-3) # == [1].depart
  @test isapprox(solved[3].arrive, Radian(2.976), rtol=1e-3)
  @test isapprox(solved[4].arrive, Radian(4.858), rtol=1e-3)
  # @test isapprox(solved[5].arrive, Radian(4.126), rtol=1e-3)
  @test isapprox(solved[5].arrive, Radian(0.0807), rtol=1e-3) #E@80,-200
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
@testitem "route2Segments" begin
  using Geometry2D, UnitTypes
  uk = Geometry2D.UnitVector(0,0,1)
  #a square of pulleys, arranged ccw from quadrant1
  pA = PlainPulley( pitch=Geometry2D.Circle( MilliMeter(100), MilliMeter(100), MilliMeter(10)), axis=uk, name="A")
  pB = PlainPulley( pitch=Geometry2D.Circle(MilliMeter(-100), MilliMeter(100), MilliMeter(10)), axis=uk, name="B")
  pC = PlainPulley( pitch=Geometry2D.Circle(MilliMeter(-100),MilliMeter(-100), MilliMeter(43)), axis=uk, name="C")
  pD = PlainPulley( pitch=Geometry2D.Circle( MilliMeter(100),MilliMeter(-100), MilliMeter(14)), axis=uk, name="D") 
  pE = PlainPulley( pitch=Geometry2D.Circle( MilliMeter(80),MilliMeter(-200), MilliMeter(14)), axis=-uk, name="E") 
  route = [pA, pB, pC, pD, pE]

  solved = calculateRouteAngles(route)
  segments = route2Segments(solved)
  @test toStringShort(segments[1]) == "A--B"
  @test toStringShort(segments[2]) == "B--C"
  @test toStringShort(segments[3]) == "C--D"
  @test toStringShort(segments[4]) == "D--E"
  @test toStringShort(segments[5]) == "E--A"
end

"""
    calculateBeltLength(segments::Vector{FreeSegment}) :: AbstractLength
  Calculates the belt length over the given `route` as the sum of straight Segments.
"""
function calculateBeltLength(segments::Vector{FreeSegment}) :: AbstractLength
  l = MilliMeter(0)
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
    calculateBeltLength(route::Vector{AbstractPulley}) :: AbstractLength
  Calculates the belt length over the given `route` as the sum of circular sections at the pulley pitch radii between the arrival and departure angles.
"""
function calculateBeltLength(route::Vector{T}) :: AbstractLength where T<:AbstractPulley
  return calculateBeltLength( route2Segments(route) ) 
end
@testitem "calculateBeltLength" begin
  using Geometry2D, UnitTypes
  uk = Geometry2D.UnitVector(0,0,1)

  #one complete revolution
  pp = PlainPulley( pitch=Geometry2D.Circle( MilliMeter(100), MilliMeter(100), MilliMeter(10)), axis=uk, name="A", arrive=Degree(0), depart=Degree(360)) # one complete revolution
  @test isapprox( calculateBeltLength( [pp] ), calculateWrappedLength(pp), rtol=1e-3 )

  # an open belt, 180d wrap on both pulleys, separated by 200mm
  pA = PlainPulley( pitch=Geometry2D.Circle( MilliMeter(100), MilliMeter(100), MilliMeter(10)), arrive=Degree(270), depart=Degree(90),               axis=uk, name="A")
  pB = PlainPulley( pitch=Geometry2D.Circle(MilliMeter(-100), MilliMeter(100), MilliMeter(10)),             arrive=Degree(90), depart=Degree(270), axis=uk, name="B")
  seg = FreeSegment( depart=pA, arrive=pB )
  @test isapprox( BeltTransmission.calculateBeltLength( [seg] ), MilliMeter(π*2*10) + MilliMeter(200), rtol=1e-3 )

  #a square of pulleys, arranged ccw from quadrant1
  pA = PlainPulley( pitch=Geometry2D.Circle( MilliMeter(100), MilliMeter(100), MilliMeter(10)), axis=uk, name="A")
  pB = PlainPulley( pitch=Geometry2D.Circle(MilliMeter(-100), MilliMeter(100), MilliMeter(10)), axis=uk, name="B")
  pC = PlainPulley( pitch=Geometry2D.Circle(MilliMeter(-100),MilliMeter(-100), MilliMeter(43)), axis=uk, name="C")
  pD = PlainPulley( pitch=Geometry2D.Circle( MilliMeter(100),MilliMeter(-100), MilliMeter(14)), axis=uk, name="D") 
  pE = PlainPulley( pitch=Geometry2D.Circle( MilliMeter(80),MilliMeter(-200), MilliMeter(14)), axis=-uk, name="E") 
  route = [pA, pB, pC, pD, pE]
  solved = BeltTransmission.calculateRouteAngles(route)
  # # @test isapprox( calculateBeltLength( solved ), 0.181155m, rtol=1e-3 ) #E@0,0
  # # @test isapprox( calculateBeltLength( solved ), 0.22438m, rtol=1e-3 ) #E@80,-200
  @test isapprox( BeltTransmission.calculateBeltLength( solved ), Meter(1.231345), rtol=1e-3 )
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
@testitem "toStringShort" begin
  using Geometry2D, UnitTypes
  uk = Geometry2D.UnitVector(0,0,1)

  pA = PlainPulley( pitch=Geometry2D.Circle( MilliMeter(100), MilliMeter(100), MilliMeter(10)), arrive=Degree(0), depart=Degree(90),               axis=uk, name="A")
  pB = PlainPulley( pitch=Geometry2D.Circle(MilliMeter(-100), MilliMeter(100), MilliMeter(10)),             arrive=Degree(90), depart=Degree(200), axis=uk, name="B")
  seg = FreeSegment( depart=pA, arrive=pB )
  @test toStringShort(seg) == "A--B"
end


"""
    toStringPoints(seg::FreeSegment) :: String
  Creates strings like:
    FreeSegment: depart[E] [-0.013m, 0.012m] --> arrive[A] [0.110m, 0.083m] l[0.142m]@[29.973°]
"""
function toStringPoints(seg::FreeSegment) :: String
  pdep = getDeparturePoint(seg)
  dstr = @sprintf("depart[%s] [%3.3f%s, %3.3f%s]",
    seg.depart.name,
    pdep.x.value, pdep.x.unit,
    pdep.y.value, pdep.y.unit
  )

  parr = getArrivalPoint(seg)
  astr = @sprintf("arrive[%s] [%3.3f%s, %3.3f%s]",
    seg.arrive.name,
    parr.x.value, parr.x.unit,
    parr.y.value, parr.y.unit
  )

  lda = norm(parr-pdep)
  ada = Geometry2D.angleDegree(parr-pdep)
  lstr = @sprintf(" l[%3.3f%s]@[%3.3f°]", lda.value, lda.unit, ada.value)

  str = "FreeSegment: " * dstr * " --> " * astr * lstr
  return str
end
@testitem "toStringPoints" begin
  using Geometry2D, UnitTypes
  uk = Geometry2D.UnitVector(0,0,1)

  pA = PlainPulley( pitch=Geometry2D.Circle( MilliMeter(100), MilliMeter(100), MilliMeter(10)), arrive=Degree(0), depart=Degree(90),               axis=uk, name="A")
  pB = PlainPulley( pitch=Geometry2D.Circle(MilliMeter(-100), MilliMeter(100), MilliMeter(10)),             arrive=Degree(90), depart=Degree(200), axis=uk, name="B")
  seg = FreeSegment( depart=pA, arrive=pB )
  @test toStringPoints(seg) == "FreeSegment: depart[A] [100.000mm, 110.000mm] --> arrive[B] [-100.000mm, 110.000mm] l[200.000mm]@[180.000°]"
end

