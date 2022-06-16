# A belt segment is a free section of belt beginning and ending at a pulley tangent point.  It is assumed straight and loaded only in tension. 

struct Segment #this should set aArrive & aDepart on the pulleys...mutable pulley?
  depart::Pulley #expanded to the Point on the `pitch` circle at `aDepart`
  arrive::Pulley #expanded to the Point on the `pitch` circle at `aArrive`
end
@kwdispatch Segment()
@kwmethod Segment(; depart::Pulley, arrive::Pulley) = Segment(depart,arrive)

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
Plots the Pulleys and Segments in a `route`.
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
  # legend_background_color --> :red
end

function Base.show(io::IO, seg::Segment)
  println(toStringShort(seg))
end


function getDeparturePoint(seg::Segment)
  getDeparturePoint(seg.depart)
end
function getArrivalPoint(seg::Segment)
  getArrivalPoint(seg.arrive) 
end

function distance(seg::Segment)
  return Geometry2D.distance( getDeparturePoint(seg), getArrivalPoint(seg) )
end


"""
`findTangents(; a::Pulley, b::Pulley, plotResult::Bool=false)`
Finds possible depart and arrive angle pairs.
For any two planar circles, four tangent lines are possible:

Returns the four possible segments, each containing a pair of pulleys that form a tangent segment

Find four lines tangent to both Pulley `a` and `b`, returns paired angles locating the points of tangency on the circles.
"""
function findTangents(seg::Segment)
  un =u"mm" # unit(a.center.x)
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
better name: doSegmentAxesAgreeWithPulleys...
define segment a->b between ai&bi; the correct angle will have cross products that match both axes, so
 (ra-a1)x(a1-b1) = ax1 && (rb-b1)x(a1-b1) = bx1, all others should be false
 this is just a Segment wrapper on Geometry2D.isSegmentMutuallyTangent
"""
function isSegmentMutuallyTangent( seg::Segment )
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
`calculateRouteAngles(route::Vector{Pulley}, plotSegments::Bool=false)::Vector{Pulley}`
Given an ordered vetor of Pulleys, output a vector of new Pulleys whose aArrive and aDepart angles are set to connect the pulleys with mutually tangent segments.
Convention: pulleys listed in 'positive' belt rotation order, consistent with each Pulley's rotation axis.
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
end #calculateRouteAngles

function route2Segments(route::Vector{Pulley}) :: Vector{Segment}
  nr = length(route) 
  segments = Vector{Segment}(undef, nr) # #pulleys == #segments
  for ir in 1:nr
    segments[ir] = Segment(depart=route[ir], arrive=route[Utility.iNext(ir,nr)])
  end
  return segments
end

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

function calculateBeltLength(route::Vector{Pulley}) :: Unitful.Length
  return calculateBeltLength( route2Segments(route) ) 
end

function toString(seg::Segment)
  return toStringShort(seg)
end
function toStringShort(seg::Segment)
  return "$(seg.depart.name)--$(seg.arrive.name)"
end

"""
`toStringPoints(seg::Segment)::String`
creates strings like:
`Segment: depart[100.000, 110.000] -- arrive[-100.000, 110.000] length[200.000]`
"""
function toStringPoints(seg::Segment)
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
`toStringPoints(seg::Segment)::String`
creates strings like:
`Segment: depart[100.000, 110.000] -- arrive[-100.000, 110.000] length[200.000]`
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


function printRoute(route::Vector{Pulley})
  for r in route #r is pulleys
    println(pulley2String(r))
  end
  lTotal = calculateBeltLength(route)
  println("total belt length = $lTotal") #No knowledge of the belt pitch, so can't list the correct belt
end

function printSegments(segments::Vector{Segment})
  for s in segments
    println(toStringVectors(s))
  end
  lTotal = calculateBeltLength(segments)
  println("total belt length = $lTotal") #No knowledge of the belt pitch, so can't list the correct belt
end


function testBeltSegment()
  uk = Geometry2D.UnitVector(0,0,1)
  #a square of pulleys, arranged ccw from quadrant1
  pA = Pulley( circle=Geometry2D.Circle( 100u"mm", 100u"mm", 10u"mm"), axis=uk, name="A")
  pB = Pulley( circle=Geometry2D.Circle(-100u"mm", 100u"mm", 10u"mm"), axis=uk, name="B")
  pC = Pulley( circle=Geometry2D.Circle(-100u"mm",-100u"mm", 43u"mm"), axis=uk, name="C")
  pD = Pulley( circle=Geometry2D.Circle( 100u"mm",-100u"mm", 14u"mm"), axis=uk, name="D") 
  pE = Pulley( circle=Geometry2D.Circle( 80u"mm",-200u"mm", 14u"mm"), axis=-uk, name="E") 
  route = [pA, pB, pC, pD, pE]

  @testset "Segment constructors" begin
    sab = Segment( pA, pB )
    @test distance(sab) == Geometry2D.distance(pB.pitch.center, pA.pitch.center)

    sab = Segment( depart=pA, arrive=pB)
    @test distance(sab) == Geometry2D.distance(pB.pitch.center, pA.pitch.center)
  end

  @testset "findTangents" begin
    saa = Segment(depart=pA, arrive=pA)
    sab = Segment(depart=pA, arrive=pB)
    sac = Segment(depart=pA, arrive=pC)
    @test_throws DomainError findTangents(saa) #overlap, throws


    tans = findTangents(sab)
    for i=1:4
      @test Geometry2D.isSegmentMutuallyTangent(cA=tans[i].depart.pitch, thA=tans[i].depart.aDepart, cB=tans[i].arrive.pitch, thB=tans[i].arrive.aArrive )
    end

    tans = findTangents(sac)
    for i=1:4
      @test Geometry2D.isSegmentMutuallyTangent(cA=tans[i].depart.pitch, thA=tans[i].depart.aDepart, cB=tans[i].arrive.pitch, thB=tans[i].arrive.aArrive )
    end

  end

  @testset "isSegmentMutuallyTangent" begin
    pA = Pulley( circle=Geometry2D.Circle( 100u"mm", 100u"mm", 10u"mm"), aArrive=0°, aDepart=(π/2)u"rad",               axis=uk, name="A")
    pB = Pulley( circle=Geometry2D.Circle(-100u"mm", 100u"mm", 10u"mm"),             aArrive=(π/2)u"rad", aDepart=200°, axis=uk, name="B")
    seg = Segment( depart=pA, arrive=pB )
    @test isSegmentMutuallyTangent( seg )

    pA = Pulley( circle=Geometry2D.Circle( 100u"mm", 100u"mm", 10u"mm"), aArrive=0°, aDepart=90°,               axis=uk, name="A")
    pB = Pulley( circle=Geometry2D.Circle(-100u"mm", 100u"mm", 10u"mm"),             aArrive=90°, aDepart=200°, axis=uk, name="B")
    seg = Segment( depart=pA, arrive=pB )
    @test isSegmentMutuallyTangent( seg )
  end

  @testset "calculateRouteAngles" begin
    solved = calculateRouteAngles(route)

    #test confirmed via plot, copying angles into below to guard changes
    # @test isapprox(solved[1].aArrive, 5.327rad, rtol=1e-3) # E@0,0
    @test isapprox(solved[1].aArrive, 6.136rad, rtol=1e-3) # E@80,-200
    @test isapprox(solved[2].aArrive, 1.571rad, rtol=1e-3) # == [1].aDepart
    @test isapprox(solved[3].aArrive, 2.976rad, rtol=1e-3)
    @test isapprox(solved[4].aArrive, 4.858rad, rtol=1e-3)
    # @test isapprox(solved[5].aArrive, 4.126rad, rtol=1e-3)
    @test isapprox(solved[5].aArrive, 0.0807rad, rtol=1e-3) #E@80,-200
  end

  @testset "toStringShort" begin
    pA = Pulley( circle=Geometry2D.Circle( 100u"mm", 100u"mm", 10u"mm"), aArrive=0°, aDepart=90°,               axis=uk, name="A")
    pB = Pulley( circle=Geometry2D.Circle(-100u"mm", 100u"mm", 10u"mm"),             aArrive=90°, aDepart=200°, axis=uk, name="B")
    seg = Segment( depart=pA, arrive=pB )
    @test toStringShort(seg) == "A--B"
  end

  @testset "toStringPoints" begin
    pA = Pulley( circle=Geometry2D.Circle( 100u"mm", 100u"mm", 10u"mm"), aArrive=0°, aDepart=90°,               axis=uk, name="A")
    pB = Pulley( circle=Geometry2D.Circle(-100u"mm", 100u"mm", 10u"mm"),             aArrive=90°, aDepart=200°, axis=uk, name="B")
    seg = Segment( depart=pA, arrive=pB )
    @test toStringPoints(seg) == "Segment: depart[100.000, 110.000] -- arrive[-100.000, 110.000] length[200.000]"
  end

  @testset "toStringVector" begin
    pA = Pulley( circle=Geometry2D.Circle( 100u"mm", 100u"mm", 10u"mm"), aArrive=0°, aDepart=90°,               axis=uk, name="A")
    pB = Pulley( circle=Geometry2D.Circle(-100u"mm", 100u"mm", 10u"mm"),             aArrive=90°, aDepart=200°, axis=uk, name="B")
    seg = Segment( depart=pA, arrive=pB )
    @test toStringVectors(seg) == "A:[100.000,100.000]<10.000@90.000°>[100.000,110.000]--B:[-100.000,100.000]<10.000@90.000°>[-100.000,110.000]"
  end

  @testset "calculateBeltLength" begin
    # #one complete revolution
    pp = Pulley( circle=Geometry2D.Circle( 100u"mm", 100u"mm", 10u"mm"), axis=uk, name="A", aArrive=0°, aDepart=360°) # one complete revolution
    @test isapprox( calculateBeltLength( [pp] ), calculateWrappedLength(pp), rtol=1e-3 )

    # an open belt, 180d wrap on both pulleys, separated by 200mm
    pA = Pulley( circle=Geometry2D.Circle( 100u"mm", 100u"mm", 10u"mm"), aArrive=270°, aDepart=90°,               axis=uk, name="A")
    pB = Pulley( circle=Geometry2D.Circle(-100u"mm", 100u"mm", 10u"mm"),             aArrive=90°, aDepart=270°, axis=uk, name="B")
    seg = Segment( depart=pA, arrive=pB )
    @test isapprox( calculateBeltLength( [seg] ), π*2*10mm + 200mm, rtol=1e-3 )

    solved = calculateRouteAngles(route)
    # # @test isapprox( calculateBeltLength( solved ), 0.181155m, rtol=1e-3 ) #E@0,0
    # # @test isapprox( calculateBeltLength( solved ), 0.22438m, rtol=1e-3 ) #E@80,-200
    @test isapprox( calculateBeltLength( solved ), 1.231345m, rtol=1e-3 )
  end

  @testset "route2Segments" begin
    solved = calculateRouteAngles(route)
    segments = route2Segments(solved)
    @test toStringShort(segments[1]) == "A--B"
    @test toStringShort(segments[2]) == "B--C"
    @test toStringShort(segments[3]) == "C--D"
    @test toStringShort(segments[4]) == "D--E"
    @test toStringShort(segments[5]) == "E--A"
  end


  @testset "plotSegment" begin
    pyplot()
    pA = Pulley( circle=Geometry2D.Circle( 100u"mm", 100u"mm", 10u"mm"), aArrive=0°, aDepart=90°,               axis=uk, name="A")
    pB = Pulley( circle=Geometry2D.Circle(-100u"mm", 100u"mm", 10u"mm"),             aArrive=90°, aDepart=200°, axis=uk, name="B")
    seg = Segment( depart=pA, arrive=pB )
    p = plot(seg, reuse=false)
    p = plot!(seg.depart)
    p = plot!(seg.arrive)
    display(p)

    @test typeof(p) <: Plots.AbstractPlot #did the plot draw at all?
  end

  @testset "plotRoute" begin
    pyplot()
    solved = calculateRouteAngles(route)
    p = plot(solved, reuse=false)#, legend_background_color=:transparent, legend_position=:outerright)
    display(p)
    
    @test typeof(p) <: Plots.AbstractPlot #did the plot draw at all?
  end

  @testset "printRoute" begin
    solved = calculateRouteAngles(route)
    printRoute(solved)
    @test true
  end

  @testset "printSegments" begin
    solved = calculateRouteAngles(route)
    printSegments( route2Segments( solved ) )
    @test true
  end

end #test


