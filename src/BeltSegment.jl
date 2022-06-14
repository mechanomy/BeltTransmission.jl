# segments only interact with pulleys, not random points...
# A belt segment is a free section of belt beginning and ending at a pulley tangent point.  It is assumed straight and loaded only in tension. 

struct Segment #this should set aArrive & aDepart on the pulleys...mutable pulley?
  depart::Pulley #expanded to the Point on the `pitch` circle at `aDepart`
  arrive::Pulley #expanded to the Point on the `pitch` circle at `aArrive`
  # depart::Geometry2D.Point #[x,y] departure point
  # arrive::Geometry2D.Point #[x,y] arrival point
  # length::Unitful.Length
end
@kwdispatch Segment()
# @kwmethod Segment(; depart::Geometry2D.Point, arrive::Geometry2D.Point ) = Segment( depart, arrive, Geometry2D.distance(depart,arrive) )
# @kwmethod Segment(; depart::Pulley, arrive::Pulley ) = Segment( depart.pitch.center, arrive.pitch.center, Geometry2D.distance(depart.pitch.center,arrive.pitch.center) )
@kwmethod Segment(; depart::Pulley, arrive::Pulley) = Segment(depart,arrive)

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
# function findTangents(; a::Pulley, b::Pulley, plotResult::Bool=false)
function findTangents(seg::Segment; plotResult::Bool=false )
  un =u"mm" # unit(a.center.x)
  # lCenter = norm(a.pitch.center-b.pitch.center)
  lCenter = Geometry2D.distance( seg.depart.pitch.center, seg.arrive.pitch.center )

  # #verify that circles do not overlap...but overlapping circles still have mutual tangents...
  # if lCenter < seg.depart.pitch.radius + seg.arrive.pitch.radius
  #   throw( DomainError(lCenter, "findTangents: circles a[$a] and b[$b] overlap, can't find tangents") )
  #   return false
  # end
  #ensure that pulleys are not coincident...this would manifest more clearly in aCross/aPara
  if lCenter < 0.001mm
    throw( DomainError(lCenter, "findTangents: pulleys on Segment[$seg] are coincident, can't find tangents") )
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

  if plotResult
    # @printf("Cross: a+b/d=%f + %f / %f = %3f = %3f deg\n", ustrip(un, a.pitch.radius), ustrip(un, b.pitch.radius), ustrip(un, lCenter), ustrip(un, aCross), ustrip(un, aCross)*57)
    # @printf("Para: a-b/d=%f + %f / %f = %3f = %3f deg\n", ustrip(un, a.pitch.radius), ustrip(un, b.pitch.radius), ustrip(un, lCenter), ustrip(un, aPara), ustrip(un, aPara)*57)
    @printf("Cross: a+b/d=%f + %f / %f = %3f = %3f deg\n", ustrip(un, a.pitch.radius), ustrip(un, b.pitch.radius), ustrip(un, lCenter), aCross,aCross*57)
    @printf("Para: a-b/d=%f + %f / %f = %3f = %3f deg\n", ustrip(un, a.pitch.radius), ustrip(un, b.pitch.radius), ustrip(un, lCenter), aPara, aPara*57)
    @printf("A: four angles to tangent points: %3.3f %3.3f, %3.3f %3.3f\n", rad2deg(a1), rad2deg(a2), rad2deg(a3), rad2deg(a4))
    @printf("B: four angles to tangent points: %3.3f %3.3f, %3.3f %3.3f\n", rad2deg(b1), rad2deg(b2), rad2deg(b3), rad2deg(b4))

    println("A1B1: ", Geometry2D.isSegmentMutuallyTangent(cA=pulley2Circle(a), cB=pulley2Circle(b), thA=uconvert(u"rad", a1), thB=uconvert(u"rad", b1)) )
    println("A2B2: ", Geometry2D.isSegmentMutuallyTangent(cA=pulley2Circle(a), cB=pulley2Circle(b), thA=uconvert(u"rad", a2), thB=uconvert(u"rad", b2)) )
    println("A3B3: ", Geometry2D.isSegmentMutuallyTangent(cA=pulley2Circle(a), cB=pulley2Circle(b), thA=uconvert(u"rad", a3), thB=uconvert(u"rad", b3)) )
    println("A4B4: ", Geometry2D.isSegmentMutuallyTangent(cA=pulley2Circle(a), cB=pulley2Circle(b), thA=uconvert(u"rad", a4), thB=uconvert(u"rad", b4)) )

    #prove it
    # Geometry2D.plotCircle(pulley2Circle(a),"black")
    # Geometry2D.plotCircle(pulley2Circle(b),"black")
    th = LinRange(0,2*π, 100)
    x = ustrip.(un, a.pitch.center.x .+ a.pitch.radius.*cos.(th) )
    y = ustrip.(un, a.pitch.center.y .+ a.pitch.radius.*sin.(th) )
    plot(x,y, label="A")
    x = ustrip.(un, b.pitch.center.x .+ b.pitch.radius.*cos.(th) )
    y = ustrip.(un, b.pitch.center.y .+ b.pitch.radius.*sin.(th) )
    plot(x,y, label="B")
    x = [ustrip(un, a.pitch.center.x) + ustrip(un, a.pitch.radius)*cos(a1), ustrip(un, b.pitch.center.x) + ustrip(un, b.pitch.radius)*cos(b1)]
    y = [ustrip(un, a.pitch.center.y) + ustrip(un, a.pitch.radius)*sin(a1), ustrip(un, b.pitch.center.y) + ustrip(un, b.pitch.radius)*sin(b1)]
    plot(x,y, color="red", label="a1b1") 
    x = [ustrip(un, a.pitch.center.x) + ustrip(un, a.pitch.radius)*cos(a2), ustrip(un, b.pitch.center.x) + ustrip(un, b.pitch.radius)*cos(b2)]
    y = [ustrip(un, a.pitch.center.y) + ustrip(un, a.pitch.radius)*sin(a2), ustrip(un, b.pitch.center.y) + ustrip(un, b.pitch.radius)*sin(b2)]
    plot(x,y, color="magenta", label="a2b2") 
    x = [ustrip(un, a.pitch.center.x) + ustrip(un, a.pitch.radius)*cos(a3), ustrip(un, b.pitch.center.x) + ustrip(un, b.pitch.radius)*cos(b3)]
    y = [ustrip(un, a.pitch.center.y) + ustrip(un, a.pitch.radius)*sin(a3), ustrip(un, b.pitch.center.y) + ustrip(un, b.pitch.radius)*sin(b3)]
    plot(x,y, color="blue", label="a3b3") 
    x = [ustrip(un, a.pitch.center.x) + ustrip(un, a.pitch.radius)*cos(a4), ustrip(un, b.pitch.center.x) + ustrip(un, b.pitch.radius)*cos(b4)]
    y = [ustrip(un, a.pitch.center.y) + ustrip(un, a.pitch.radius)*sin(a4), ustrip(un, b.pitch.center.y) + ustrip(un, b.pitch.radius)*sin(b4)]
    p = plot(x,y, color="cyan", label="a4b4") 
    legend()
    BPlot.formatPlot()
    display(p)
    # show(p)
    # gui()
  end

  # return [ [a1,b1], [a2,b2], [a3,b3], [a4,b4] ].*u"rad"
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
end #findTangents

"""
better name: doSegmentAxesAgreeWithPulleys...
define segment a->b between ai&bi; the correct angle will have cross products that match both axes, so
 (ra-a1)x(a1-b1) = ax1 && (rb-b1)x(a1-b1) = bx1, all others should be false
 this is just a Segment wrapper on Geometry2D.isSegmentMutuallyTangent
"""
# function isSegmentMutuallyTangent(; a::Pulley, b::Pulley, thA::Geometry2D.Radian, thB::Geometry2D.Radian)
function isSegmentMutuallyTangent( seg::Segment )
 #versus Geometry2D.isSegmentMutuallyTangent(), this compares the cross product to the pulley axis to test that the cross is in the same direction as the pulley's positive roatation

  a =   seg.depart
  thA = seg.depart.aDepart
  b =   seg.arrive
  thB = seg.arrive.aArrive
  
  raa4 = a.pitch.radius * [cos(thA), sin(thA),0]
  rbb4 = b.pitch.radius * [cos(thB), sin(thB),0]
  a4b4 = ([b.pitch.center.x,b.pitch.center.y,0u"mm"]+rbb4) - ([a.pitch.center.x,a.pitch.center.y,0u"mm"]+raa4) #difference between tangent points, a to b, defines the belt segment
  # println("a is at ", [a.pitch.center.x,a.pitch.center.y,0u"mm"]+raa4)
  # println("b is at ", [b.pitch.center.x,b.pitch.center.y,0u"mm"]+rbb4)

  uraa4 = normalize(ustrip.(u"mm",raa4)) #normalization cancels units
  urbb4 = normalize(ustrip.(u"mm", rbb4) )
  ua4b4 = normalize(ustrip.(u"mm", a4b4) )
  ca4 = cross(uraa4, ua4b4)
  cb4 = cross(urbb4, ua4b4)
  da4 = dot(ca4, Geometry2D.toVector(a.axis) )
  db4 = dot(cb4, Geometry2D.toVector(b.axis) )
  return isapprox(da4, 1, rtol=1e-3) && isapprox(db4, 1, rtol=1e-3)
  # # return Geometry2D.isSegmentMutuallyTangent(cA=pulley2Circle(a), cB=pulley2Circle(b), thA=thA, thB=thB )
end

"""
`calculateSegments(route::Vector{Pulley}, plotSegments::Bool=false)::Vector{Pulley}`
Given an ordered vetor of Pulleys, output a vector of new Pulleys whose aArrive and aDepart angles are set to connect the pulleys with mutually tangent segments.
Convention: pulleys listed in 'positive' belt rotation order, consistent with each Pulley's rotation axis.
"""
function calculateSegments(route::Vector{Pulley}, plotSegments::Bool=false)
  nr = size(route,1)
  solved = route #allocate the array

  for ir in 1:1:nr
    a = route[ir]
    b = route[Utility.iNext(ir,nr)]
    un =u"mm" # unit(a.pitch.center.x)
    # angles = findTangents(a=a, b=b) #angles = [[a1,b1],[a2,b2],...]
    segments = findTangents(Segment(depart=a, arrive=b))

    for ia in 1:4 # there are 4 angle solutions in angles
      # thA=uconvert(u"rad", angles[ia][1])
      # thB=uconvert(u"rad", angles[ia][2])
      thA = segments[ia].depart.aDepart
      thB = segments[ia].arrive.aArrive
      # ta = isSegmentMutuallyTangent(a=a, b=b, thA=thA, thB=thB )
      ta = isSegmentMutuallyTangent( segments[ia] )
      if ta 
        # solved[ir]                   = Pulley(a.pitch, a.axis, a.aArrive, thA, a.name )
        # solved[Utility.iNext(ir,nr)] = Pulley(b.pitch, b.axis, thB, b.aDepart, b.name )
        solved[ir]                   = segments[ia].depart
        solved[Utility.iNext(ir,nr)] = segments[ia].arrive

      end
    end
  end

  if plotSegments
    for i in 1:length(solved)
      i0 = i
      i1 = Utility.iNext(i, length(solved))

      th = LinRange(0,2*π, 100)
      x = ustrip.(mm, solved[i0].pitch.center.x .+ solved[i0].pitch.radius.*cos.(th) )
      y = ustrip.(mm, solved[i0].pitch.center.y .+ solved[i0].pitch.radius.*sin.(th) )
      plot(x,y, label=solved[i0].name )
      text(ustrip(mm,solved[i0].pitch.center.x), ustrip(mm,solved[i0].pitch.center.y), solved[i0].name )

      pa = Geometry2D.pointOnCircle( pulley2Circle(solved[i0]), solved[i0].aDepart )
      pb = Geometry2D.pointOnCircle( pulley2Circle(solved[i1]), solved[i1].aArrive )
      x = ustrip.(mm, [pa.x, pb.x])
      y = ustrip.(mm, [pa.y, pb.y])
      plot(x,y, "g--", label=i)
    end
    # legend()
    BPlot.formatPlot()

  end

  return solved
end #calculateSegments

# convert a Pulley array to a belt/free list
function routeToBeltSystem(route::Vector{Pulley})
  nr = size(route,1)
  belt = []
  for ir in 1:nr #this loop looks forward from a pulley, adding pulley then freespace segment
    a = route[ir] #current pulley
    b = route[Utility.iNext(ir,nr)] #next pulley

    raa = a.pitch.radius * [cos(a.aDepart), sin(a.aDepart),0]
    rbb = b.pitch.radius * [cos(b.aArrive), sin(b.aArrive),0]
    from = [a.pitch.center.x,a.pitch.center.y,0u"mm"]+raa
    to =   [b.pitch.center.x,b.pitch.center.y,0u"mm"]+rbb
    # seg = Segment( Geometry2D.Point(from[1], from[2]), Geometry2D.Point(to[1], to[2]), norm(to-from))
    seg = Segment( depart=a, arrive=b )

    append!(belt, [a])
    append!(belt, [seg])
  end

  return belt
end #routeToBeltSystem

function calculateBeltLength(beltSystem)
  l = 0u"mm"
  for b in beltSystem
    if typeof(b) == Pulley
      l += calculateWrappedLength(b)
    end
    if typeof(b) == Segment
      # l += b.length
      l += distance(b)
    end
  end
  return l
end

function printRoute(route::Vector{Pulley})
  for r in route
    un = unit(r.pitch.center.x)
    @printf("center[%3.3f, %3.3f] radius[%3.3f] arrive[%3.3f deg] depart[%3.3f deg]\n", ustrip(un, r.pitch.center.x), ustrip(un, r.pitch.center.y), ustrip(un, r.pitch.radius), rad2deg(ustrip(r.aArrive)), rad2deg(ustrip(r.aDepart)) )
  end
end

function toString(thing::Pulley)
  un = unit(thing.pitch.center.x)
  str = @sprintf("Pulley: [%s] center[%3.3f, %3.3f] radius[%3.3f] arrive[%3.3f deg] depart[%3.3f deg]",
  thing.name,
  ustrip(un, thing.pitch.center.x), ustrip(un, thing.pitch.center.y), ustrip(un, thing.pitch.radius),
  rad2deg(ustrip(un, thing.aArrive)), rad2deg(ustrip(un, thing.aDepart)) )
  # println("toString = ", str)
  return str
end
function toString(thing::Segment)
  un = unit(thing.depart.x)
  str = @sprintf("Segment: depart[%3.3f, %3.3f] -- arrive[%3.3f, %3.3f] length[%3.3f]",
  ustrip(un, thing.depart.x), ustrip(un, thing.depart.y),
  ustrip(un, thing.arrive.x), ustrip(un, thing.arrive.y),
  # ustrip(thing.length) )
  ustrip(distance(thing) ) )
  # println("toString = ", str)
  return str
end

# prints <beltSystem> by calling toString() on each element
function printBeltSystem(beltSystem)
  for (i,b) in enumerate(beltSystem)
    if typeof(b) == Pulley
      println("$i: ", pulley2String(b))
      # printPulley(b)
    else
      println("$i: ", toString(b))
    end
  end
  lTotal = calculateBeltLength(beltSystem)
  println("total belt length = $lTotal") #No knowledge of the belt pitch, so can't list the correct belt

end

function plotBeltSystem(beltSystem; colorPulley="black",colorSegment="orange", linewidthBelt=4, plotUnit=u"mm")
  # nb = size(beltSystem,1)
  for (i,b) in enumerate(beltSystem)
    if typeof(b) == Pulley
      plotPulley(b, colorPulley=colorPulley, colorBelt=colorSegment, linewidthBelt=linewidthBelt, plotUnit=plotUnit)
      # Geometry2D.plotCircle(pulley2Circle(b), colorPulley)
    end
    if typeof(b) == Segment #plot segments after pulleys
      x = [ustrip(b.depart.x), ustrip(b.arrive.x) ]
      y = [ustrip(b.depart.y), ustrip(b.arrive.y) ]
      # x = [ustrip(plotUnit, b.depart.x), ustrip(plotUnit, b.arrive.x) ]
      # y = [ustrip(plotUnit, b.depart.y), ustrip(plotUnit, b.arrive.x) ]
      plot(x,y, color=colorSegment, linewidth=linewidthBelt, alpha=0.5, label=toString(b))
    end
  end
  BPlot.formatPlot()
end

function testBeltSegment()

  uk = Geometry2D.UnitVector(0,0,1)
  #a square of pulleys, arranged ccw from quadrant1
  pA = Pulley( circle=Geometry2D.Circle( 100u"mm", 100u"mm", 10u"mm"), axis=uk, name="A")
  pB = Pulley( circle=Geometry2D.Circle(-100u"mm", 100u"mm", 10u"mm"), axis=uk, name="B")
  pC = Pulley( circle=Geometry2D.Circle(-100u"mm",-100u"mm", 43u"mm"), axis=uk, name="C")
  pD = Pulley( circle=Geometry2D.Circle( 100u"mm",-100u"mm", 14u"mm"), axis=uk, name="D") 
  pE = Pulley( circle=Geometry2D.Circle( 0u"mm",0u"mm", 14u"mm"), axis=-uk, name="E") 
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

    tans = findTangents(sab, plotResult=false)
    for i=1:4
      # @test Geometry2D.isSegmentMutuallyTangent(cA=pulley2Circle(pA), cB=pulley2Circle(pB), thA=tans[i][1], thB=tans[i][2] )
      @test Geometry2D.isSegmentMutuallyTangent(cA=tans[i].depart.pitch, thA=tans[i].depart.aDepart, cB=tans[i].arrive.pitch, thB=tans[i].arrive.aArrive )
    end
    tans = findTangents(sac, plotResult=false)
    for i=1:4
      # @test Geometry2D.isSegmentMutuallyTangent(cA=pulley2Circle(pA), cB=pulley2Circle(pC), thA=tans[i][1], thB=tans[i][2] )
      @test Geometry2D.isSegmentMutuallyTangent(cA=tans[i].depart.pitch, thA=tans[i].depart.aDepart, cB=tans[i].arrive.pitch, thB=tans[i].arrive.aArrive )
    end
  end

  @testset "isSegmentMutuallyTangent" begin
    # @test isSegmentMutuallyTangent( a=pA, b=pB, thA=(π/2)u"rad", thB=(π/2)u"rad" ) == true
    pA = Pulley( circle=Geometry2D.Circle( 100u"mm", 100u"mm", 10u"mm"), aArrive=0°, aDepart=(π/2)u"rad",               axis=uk, name="A")
    pB = Pulley( circle=Geometry2D.Circle(-100u"mm", 100u"mm", 10u"mm"),             aArrive=(π/2)u"rad", aDepart=200°, axis=uk, name="B")
    seg = Segment( depart=pA, arrive=pB )
    @test isSegmentMutuallyTangent( seg )

    # @test isSegmentMutuallyTangent( a=pA, b=pB, thA=90°, thB=90° ) == true
    pA = Pulley( circle=Geometry2D.Circle( 100u"mm", 100u"mm", 10u"mm"), aArrive=0°, aDepart=90°,               axis=uk, name="A")
    pB = Pulley( circle=Geometry2D.Circle(-100u"mm", 100u"mm", 10u"mm"),             aArrive=90°, aDepart=200°, axis=uk, name="B")
    seg = Segment( depart=pA, arrive=pB )
    @test isSegmentMutuallyTangent( seg )
  end

  @testset "calculateSegments" begin
    solved = calculateSegments(route, false)

    #test confirmed via plot, copying angles into below to guard changes
    @test isapprox(solved[1].aArrive, 5.327rad, rtol=1e-3)
    @test isapprox(solved[2].aArrive, 1.571rad, rtol=1e-3) # == [1].aDepart
    @test isapprox(solved[3].aArrive, 2.976rad, rtol=1e-3)
    @test isapprox(solved[4].aArrive, 4.858rad, rtol=1e-3)
    @test isapprox(solved[5].aArrive, 4.126rad, rtol=1e-3)
  end

  @testset "calculateBeltLength" begin
    solved = calculateSegments(route, false)
    @test isapprox( calculateBeltLength( solved ), 0.181155m, rtol=1e-3 )
  end
end #test


