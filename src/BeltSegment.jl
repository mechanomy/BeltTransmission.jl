
# A belt segment is a free section of belt beginning and ending at a pulley tangent point.  It is assumed straight and loaded only in tension. 
#   using KeywordDispatch
#   using LinearAlgebra #for cross(), dot(), norm()
#   using Printf
#   using PyPlot #can use matplotlib arguments directly
#   using Unitful
#   using Geometry2D
#   using Utility
#   using BPlot


  struct Segment
    depart::Geometry2D.Point #[x,y] departure point
    arrive::Geometry2D.Point #[x,y] arrival point
    length::Unitful.Length
  end
  @kwdispatch Segment()
  @kwmethod Segment(; depart::Geometry2D.Point, arrive::Geometry2D.Point ) = Segment( depart, arrive, Geometry2D.distance(depart,arrive) )

  #find the four lines tangent to both circles, returns paired angles locating the points of tangency on the circles
  function findTangents(; a::Pulley, b::Pulley, plotResult::Bool=false)
      # println("a: ", a)
      # println("b: ", b)
      un =u"mm" # unit(a.center.x)

      lCenter = norm(a.center-b.center)
      #verify that circles do not overlap
      if lCenter < a.radius+b.radius
          println("Geometry2D.findTangents: circles overlap, can't find tangents")
          return false
      end

      aCenter = Geometry2D.angle( a.center-b.center )

      aCross = acos( (a.radius+b.radius) / lCenter )
      aPara = acos( (a.radius-b.radius) / lCenter )
      
      #four angles on A
      a1 = Geometry2D.angleWrap( aCenter+aPara )
      a2 = Geometry2D.angleWrap( aCenter-aPara )
      a3 = Geometry2D.angleWrap( aCenter+aCross )
      a4 = Geometry2D.angleWrap( aCenter-aCross )

      #four complimentary angles on B
      b1 = Geometry2D.angleWrap( aCenter+aPara )
      b2 = Geometry2D.angleWrap( aCenter-aPara )
      b3 = Geometry2D.angleWrap( -(pi-aCenter-aCross) )
      b4 = Geometry2D.angleWrap( pi+aCenter-aCross )

      if plotResult
          @printf("Cross: a+b/d=%f + %f / %f = %3f = %3f deg\n", ustrip(un, a.radius), ustrip(un, b.radius), ustrip(un, lCenter), ustrip(un, aCross), ustrip(un, aCross)*57)
          @printf("Para: a-b/d=%f + %f / %f = %3f = %3f deg\n", ustrip(un, a.radius), ustrip(un, b.radius), ustrip(un, lCenter), ustrip(un, aPara), ustrip(un, aPara)*57)
          @printf("A: four angles to tangent points: %3.3f %3.3f, %3.3f %3.3f\n", rad2deg(a1), rad2deg(a2), rad2deg(a3), rad2deg(a4))
          @printf("B: four angles to tangent points: %3.3f %3.3f, %3.3f %3.3f\n", rad2deg(b1), rad2deg(b2), rad2deg(b3), rad2deg(b4))

          println("A1B1: ", Geometry2D.isSegmentTangent(a, b, uconvert(u"rad", a1), uconvert(u"rad", b1)) )
          println("A2B2: ", Geometry2D.isSegmentTangent(a, b, uconvert(u"rad", a2), uconvert(u"rad", b2)) )
          println("A3B3: ", Geometry2D.isSegmentTangent(a, b, uconvert(u"rad", a3), uconvert(u"rad", b3)) )
          println("A4B4: ", Geometry2D.isSegmentTangent(a, b, uconvert(u"rad", a4), uconvert(u"rad", b4)) )

          #prove it
          Geometry2D.plotCircle(pulley2Circle(a),"black")
          Geometry2D.plotCircle(pulley2Circle(b),"black")
          x = [ustrip(un, a.center.x) + ustrip(un, a.radius)*cos(a1), ustrip(un, b.center.x) + ustrip(un, b.radius)*cos(b1)]
          y = [ustrip(un, a.center.y) + ustrip(un, a.radius)*sin(a1), ustrip(un, b.center.y) + ustrip(un, b.radius)*sin(b1)]
          plot(x,y, color="red") 
          x = [ustrip(un, a.center.x) + ustrip(un, a.radius)*cos(a2), ustrip(un, b.center.x) + ustrip(un, b.radius)*cos(b2)]
          y = [ustrip(un, a.center.y) + ustrip(un, a.radius)*sin(a2), ustrip(un, b.center.y) + ustrip(un, b.radius)*sin(b2)]
          plot(x,y, color="magenta") 
          x = [ustrip(un, a.center.x) + ustrip(un, a.radius)*cos(a3), ustrip(un, b.center.x) + ustrip(un, b.radius)*cos(b3)]
          y = [ustrip(un, a.center.y) + ustrip(un, a.radius)*sin(a3), ustrip(un, b.center.y) + ustrip(un, b.radius)*sin(b3)]
          plot(x,y, color="blue") 
          x = [ustrip(un, a.center.x) + ustrip(un, a.radius)*cos(a4), ustrip(un, b.center.x) + ustrip(un, b.radius)*cos(b4)]
          y = [ustrip(un, a.center.y) + ustrip(un, a.radius)*sin(a4), ustrip(un, b.center.y) + ustrip(un, b.radius)*sin(b4)]
          p = plot(x,y, color="cyan") 
          # display(p)
          # show(p)
          # gui()
      end
      return [ [a1,b1], [a2,b2], [a3,b3], [a4,b4] ]
  end #findTangents

  #define segment a->b between ai&bi; the correct angle will have cross products that match both axes, so
  # (ra-a1)x(a1-b1) = ax1 && (rb-b1)x(a1-b1) = bx1, all others should be false
  function testAngle(; a::Pulley, b::Pulley, thA::Geometry2D.Radian, thB::Geometry2D.Radian)
    raa4 = a.radius * [cos(thA), sin(thA),0]
    rbb4 = b.radius * [cos(thB), sin(thB),0]
    a4b4 = ([b.center.x,b.center.y,0u"mm"]+rbb4) - ([a.center.x,a.center.y,0u"mm"]+raa4) #difference between tangent points, a to b, defines the belt segment
    # println("a is at ", [a.center.x,a.center.y,0u"mm"]+raa4)
    # println("b is at ", [b.center.x,b.center.y,0u"mm"]+rbb4)
    uraa4 = normalize(ustrip.(u"mm",raa4)) #normalization cancels units

    urbb4 = Geometry2D.normalize(ustrip.(u"mm", rbb4) )
    ua4b4 = Geometry2D.normalize(ustrip.(u"mm", a4b4) )
    ca4 = dot(cross(uraa4, ua4b4), Geometry2D.toVector(a.axis) )
    cb4 = dot(cross(urbb4, ua4b4), Geometry2D.toVector(b.axis) )
    # println("ca4: ",ca4)
    # println("cb4: ",cb4)
    return isapprox(ca4, 1, rtol=1e-3) && isapprox(cb4, 1, rtol=1e-3)
  end

  # given a Pulley route, output a new Pulley route array with the solved angles
  function calculateSegments(route::Vector{Pulley}, plotSegments::Bool=false)
      nr = size(route,1)
      solved = route #allocate the array

      for ir in 1:1:nr
          a = route[ir]
          b = route[Utility.iNext(ir,nr)]
          # println("a = ", a)
          # println("b = ", b)
          un =u"mm" # unit(a.center.x)
          if plotSegments
              Geometry2D.plotCircle(pulley2Circle(a), "black")
          end
          angles = findTangents(a=a, b=b) #angles = [[a1,b1],[a2,b2],...]

          # println("testAngle1 ", testAngle(a=a,b=b, thA=uconvert(u"rad", angles[1][1]), thB=uconvert(u"rad", angles[1][2])))
          # println("testAngle2 ", testAngle(a=a,b=b, thA=uconvert(u"rad", angles[2][1]), thB=uconvert(u"rad", angles[2][2])))
          # println("testAngle3 ", testAngle(a=a,b=b, thA=uconvert(u"rad", angles[3][1]), thB=uconvert(u"rad", angles[3][2])))
          # println("testAngle4 ", testAngle(a=a,b=b, thA=uconvert(u"rad", angles[4][1]), thB=uconvert(u"rad", angles[4][2])))
          for ia in 1:4 # there are 4 angle solutions in angles
              thA=uconvert(u"rad", angles[ia][1])
              thB=uconvert(u"rad", angles[ia][2])
              ta = testAngle(a=a,b=b, thA = thA, thB=thB )
              if ta 
                  solved[ir]                   = Pulley(a.center, a.radius, a.axis, a.aArrive, thA, a.name )
                  solved[Utility.iNext(ir,nr)] = Pulley(b.center, b.radius, b.axis, thB, b.aDepart, b.name )
              end
              if ta && plotSegments
                  x = [ustrip(un, a.center.x) + ustrip(un, a.radius)*cos(thA), ustrip(un, b.center.x) + ustrip(un, b.radius)*cos(thB)]
                  y = [ustrip(un, a.center.y) + ustrip(un, a.radius)*sin(thA), ustrip(un, b.center.y) + ustrip(un, b.radius)*sin(thB)]
                  plot(x,y, color="orange")
              end
          end
      end

      if plotSegments
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

          raa = a.radius * [cos(a.aDepart), sin(a.aDepart),0]
          rbb = b.radius * [cos(b.aArrive), sin(b.aArrive),0]
          from = [a.center.x,a.center.y,0u"mm"]+raa
          to =   [b.center.x,b.center.y,0u"mm"]+rbb
          seg = Segment(Geometry2D.Point(from[1], from[2]), Geometry2D.Point(to[1], to[2]), norm(to-from))

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
            l += b.length
          end
      end
      return l
  end

  function printRoute(route::Vector{Pulley})
      for r in route
          un = unit(r.center.x)
          @printf("center[%3.3f, %3.3f] radius[%3.3f] arrive[%3.3f deg] depart[%3.3f deg]\n", ustrip(un, r.center.x), ustrip(un, r.center.y), ustrip(un, r.radius), rad2deg(ustrip(r.aArrive)), rad2deg(ustrip(r.aDepart)) )
      end
  end

  function toString(thing::Pulley)
      un = unit(thing.center.x)
      str = @sprintf("Pulley: [%s] center[%3.3f, %3.3f] radius[%3.3f] arrive[%3.3f deg] depart[%3.3f deg]",
          thing.name,
          ustrip(un, thing.center.x), ustrip(un, thing.center.y), ustrip(un, thing.radius),
          rad2deg(ustrip(un, thing.aArrive)), rad2deg(ustrip(un, thing.aDepart)) )
      # println("toString = ", str)
      return str
  end
  function toString(thing::Segment)
      un = unit(thing.depart.x)
      str = @sprintf("Segment: depart[%3.3f, %3.3f] -- arrive[%3.3f, %3.3f] length[%3.3f]",
          ustrip(un, thing.depart.x), ustrip(un, thing.depart.y),
          ustrip(un, thing.arrive.x), ustrip(un, thing.arrive.y),
          ustrip(thing.length) )
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

  function test()
      println("BeltSegment.test()")
      close("all")
      # println(Base.loaded_modules)

      uk = Geometry2D.UnitVector([0,0,1])
      pA = Pulley( center=Geometry2D.Point(0u"mm",0u"mm"), radius=62u"mm", axis=uk)
      pB = Pulley( center=Geometry2D.Point(146u"mm",80u"mm"), radius=43u"mm", axis=uk)
      pC = Pulley( center=Geometry2D.Point(46u"mm",180u"mm"), radius=43u"mm", axis=uk)
      pD = Pulley( center=Geometry2D.Point(0u"mm",100u"mm"), radius=4u"mm", axis=-uk) # axis is outside, rotates negatively, solves correctly

      # angles = findTangents(a=pA, b=pB, plotResult=true)

      #convention: pulleys listed in 'positive' belt rotation order
      route = [pA, pB, pC, pD]
      solved = calculateSegments(route, false)
      belt = routeToBeltSystem(solved)
      printBeltSystem(belt)
      plotBeltSystem(belt)

  end #test

  function testUnitPulleys()
      uk = Geometry2D.UnitVector([0,0,1])
      pA = PulleyKw( center=Geometry2D.Point(0u"m",0u"m"), radius=1u"m", axis=uk, "pA")
      pB = PulleyKw( center=Geometry2D.Point(10u"m",0u"m"), radius=1u"m", axis=uk, "pB")
      belt = routeToBeltSystem( calculateSegments( [pA, pB], false) )
      lTotal = calculateBeltLength(belt) 
      println("testUnitPulleys: totalLength = [$lTotal] =?= 10+10+3.14+3.14=26.28m ")
      # printBeltSystem(belt)
  end


