module BeltTransmission


module Pulley2D
    using Unitful
    using PyPlot #can use matplotlib arguments directly
    using BPlot
    using Printf
    using StaticArrays #for defined-length arrays: SVector{3,T}
    using Utility
    using Geometry2D

    struct Pulley
        center::Geometry2D.Point #[x,y] of the pulley center
        radius::Unitful.Length
        axis::Geometry2D.UnitVector #unit vector in the direction of positive axis rotation
        aArrive::Geometry2D.Radian #angle of the point of tangency 
        aDepart::Geometry2D.Radian
        name::String
    end
    Pulley(center::Geometry2D.Point, radius::Unitful.Length, axis::Geometry2D.UnitVector, name::String)     = Pulley(center,radius,axis,0u"rad",0u"rad",name) 
    Pulley(center::Geometry2D.Point, radius::Unitful.Length, axis::Geometry2D.UnitVector)                   = Pulley(center,radius,axis,0u"rad",0u"rad","") 
    Pulley(center::Geometry2D.Point, radius::Unitful.Length, name::String)                                  = Pulley(center,radius,Geometry2D.uk,0u"rad",0u"rad",name) 
    Pulley(center::Geometry2D.Point, radius::Unitful.Length)                                                = Pulley(center,radius,Geometry2D.uk,0u"rad",0u"rad","") 
    PulleyKw(; center::Geometry2D.Point, radius::Unitful.Length, axis::Geometry2D.UnitVector, name::String) = Pulley(center,radius,axis,0u"rad",0u"rad",name)

    function calculateWrappedAngle(p::Pulley) #calculate the wrapped angle from aArrive to aDepart
      if p.axis == Geometry2D.UnitVector(0,0,1) #+z == ccw
        if p.aDepart < p.aArrive #negative to positive zero crossing
          angle = (2u"rad"*pi - p.aArrive) + p.aDepart 
          # @printf("W] %s: %s -- %s = %s == %s -- %s = %s\n", p.name, uconvert(u"°",p.aArrive), uconvert(u"°",p.aDepart), uconvert(u"°",angle), p.aArrive, p.aDepart, angle)
          return angle
        else
          angle = p.aDepart - p.aArrive
          # @printf("X] %s: %s -- %s = %s == %s -- %s = %s\n", p.name, uconvert(u"°",p.aArrive), uconvert(u"°",p.aDepart), uconvert(u"°",angle), p.aArrive, p.aDepart, angle)
          return angle
        end
      elseif p.axis == Geometry2D.UnitVector(0,0,-1) #-z == cw
        if p.aDepart < p.aArrive
          angle = p.aArrive-p.aDepart
          # @printf("Y] %s: %s -- %s = %s == %s -- %s = %s\n", p.name, uconvert(u"°",p.aArrive), uconvert(u"°",p.aDepart), uconvert(u"°",angle), p.aArrive, p.aDepart, angle)
          return angle
        else
          angle = 2u"rad"*pi - p.aDepart + p.aArrive
          # @printf("Z] %s: %s -- %s = %s == %s -- %s = %s\n", p.name, uconvert(u"°",p.aArrive), uconvert(u"°",p.aDepart), uconvert(u"°",angle), p.aArrive, p.aDepart, angle)
          return angle 
        end       
      end
    end
    function calculateWrappedLength(p::Pulley) #calculate the wrapped length from aArrive to aDepart at radius
      return p.radius * calculateWrappedAngle(p)
    end

    function pulley2Circle(p::Pulley)
        return Geometry2D.Circle(p.center, p.radius)
    end

    function pulley2String(p::Pulley)
      # return @sprintf("pulley[%s] @ [%3.3f,%3.3f] r[%3.3f] arrive[%3.3f] depart[%3.3f]", p.name, p.center.x, p.center.y, p.radius, p.aArrive, p.aDepart)
      # return @sprintf("pulley[%s] @ [%s,%s] r[%s] arrive[%s] depart[%s] aWrap[%s] lWrap[%s]", p.name, p.center.x, p.center.y, p.radius, p.aArrive, p.aDepart, calculateWrappedAngle(p), calculateWrappedLength(p))
      return @sprintf("pulley[%s] @ [%s,%s] r[%s] arrive[%s] depart[%s] aWrap[%s] lWrap[%s]", p.name, p.center.x, p.center.y, p.radius, uconvert(u"°",p.aArrive), uconvert(u"°",p.aDepart), uconvert(u"°",calculateWrappedAngle(p)), calculateWrappedLength(p))
    end
    function printPulley(p::Pulley)
      println(pulley2String(p))
    end

    function plotPulley(p::Pulley; colorPulley="black", colorBelt="magenta", linewidthBelt=4, plotUnit=u"m")
      th = range(0,2*pi,length=100)

      px = ustrip(plotUnit, p.center.x) 
      py = ustrip(plotUnit, p.center.y) 
      pr = ustrip(plotUnit, p.radius)
      x = px .+ pr.*cos.(th)
      y = py .+ pr.*sin.(th)
      al= 0.5
      plot(x,y, color=colorPulley, alpha=al )
      text(px+pr*0.1,py+pr*0.1, p.name)
      if p.axis == Geometry2D.UnitVector(0,0,1) #+z == ccw
        plot(px, py, "o", color=colorPulley, alpha=al ) #arrow tip coming out of the page = ccw normal rotation
        plot(px+pr, py, "^", color=colorPulley, alpha=al)
        
        if p.aDepart < p.aArrive
          an = range(p.aArrive-2u"rad"*pi, p.aDepart, length=100)
        else
          an = range(p.aArrive,p.aDepart,length=100)
        end
        ax = px .+ pr.*cos.(an)
        ay = py .+ pr.*sin.(an)
        plot(ax,ay, color=colorBelt, alpha=al, linewidth=linewidthBelt, label=p.name )
      elseif p.axis == Geometry2D.UnitVector(0,0,-1) #-z == cw
        plot(px, py, "x", color=colorPulley, alpha=al ) #arrow tip coming out of the page = ccw normal rotation
        plot(px+pr, py, "v", color=colorPulley, alpha=al)

        if p.aDepart < p.aArrive
          an = range(p.aArrive,p.aDepart,length=100)
        else
          an = range(p.aArrive, p.aDepart-2u"rad"*pi, length=100)
        end       
        ax = px .+ pr.*cos.(an)
        ay = py .+ pr.*sin.(an)
        plot(ax,ay, color=colorBelt, alpha=al, linewidth=linewidthBelt, label=p.name )
      else
        error("BeltTransmission.Pulley2D given a non-z axis for pulley %s", pulley2String(p))
      end

    end

    function dev()
      close("all")
      ctr = Geometry2D.Point(1u"mm", 3u"mm")
      uk = Geometry2D.UnitVector(0,0,1)
      # constructLiteral = Pulley(ctr, 10u"mm", axx, 90u"deg", 270u"deg" )
      # constructLiteral = Pulley(ctr, 10u"mm", axx, 90u"degree", 270u"degree" )
      # constructLiteral = Pulley(ctr, 10u"mm", axx, 90deg, 270deg )
      constructLiteral = Pulley2D.Pulley(ctr, 10u"mm", uk, 1u"rad", 2u"rad", "constructLiteral" )
      print(constructLiteral)
      Pulley2D.plotPulley(constructLiteral)
    end

end



# A belt segment is a free section of belt beginning and ending at a pulley tangent point.  It is assumed straight and loaded only in tension. 
module BeltSegment
    using LinearAlgebra #for cross(), dot(), norm()
    using Printf
    using PyPlot #can use matplotlib arguments directly
    using Unitful
    using Geometry2D
    using Utility
    using BPlot
    import ..Pulley2D
    struct Segment
      depart::Geometry2D.Point #[x,y] departure point
      arrive::Geometry2D.Point #[x,y] arrival point
      length::Unitful.Length
    end

    #find the four lines tangent to both circles, returns paired angles locating the points of tangency on the circles
    function findTangents(; a::Pulley2D.Pulley, b::Pulley2D.Pulley, plotResult::Bool=false)
        # println("a: ", a)
        # println("b: ", b)
        un =u"mm" # unit(a.center.x)

        lCenter = norm(Geometry2D.subtractPoints(a.center,b.center))
        #verify that circles do not overlap
        if lCenter < a.radius+b.radius
            println("Geometry2D.findTangents: circles overlap, can't find tangents")
            return false
        end

        aCenter = Geometry2D.angleBetweenPoints( a.center, b.center )

        aCross = acos( (a.radius+b.radius) / lCenter )
        aPara = acos( (a.radius-b.radius) / lCenter )
        
        #four angles on A
        a1 = Geometry2D.angleCorrect( aCenter+aPara )
        a2 = Geometry2D.angleCorrect( aCenter-aPara )
        a3 = Geometry2D.angleCorrect( aCenter+aCross )
        a4 = Geometry2D.angleCorrect( aCenter-aCross )

        #four complimentary angles on B
        b1 = Geometry2D.angleCorrect( aCenter+aPara )
        b2 = Geometry2D.angleCorrect( aCenter-aPara )
        b3 = Geometry2D.angleCorrect( -(pi-aCenter-aCross) )
        b4 = Geometry2D.angleCorrect( pi+aCenter-aCross )

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
            Geometry2D.plotCircle(Pulley2D.pulley2Circle(a),"black")
            Geometry2D.plotCircle(Pulley2D.pulley2Circle(b),"black")
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
    function testAngle(; a::Pulley2D.Pulley, b::Pulley2D.Pulley, thA::Geometry2D.Radian, thB::Geometry2D.Radian)
        raa4 = a.radius * [cos(thA), sin(thA),0]
        rbb4 = b.radius * [cos(thB), sin(thB),0]
        a4b4 = ([b.center.x,b.center.y,0u"mm"]+rbb4) - ([a.center.x,a.center.y,0u"mm"]+raa4) #difference between tangent points, a to b, defines the belt segment
        # println("a is at ", [a.center.x,a.center.y,0u"mm"]+raa4)
        # println("b is at ", [b.center.x,b.center.y,0u"mm"]+rbb4)
        uraa4 = Geometry2D.normalize(raa4)
        urbb4 = Geometry2D.normalize(rbb4)
        ua4b4 = Geometry2D.normalize(a4b4)
        # ca4 = dot(cross(uraa4, ua4b4), route[ir]["axis"])
        # cb4 = dot(cross(urbb4, ua4b4), route[Utility.iNext(ir,nr)]["axis"])
        ca4 = dot(cross(uraa4, ua4b4), a.axis )
        cb4 = dot(cross(urbb4, ua4b4), b.axis )
        # println("ca4: ",ca4)
        # println("cb4: ",cb4)
        return Utility.eqTol(ca4, 1) && Utility.eqTol(cb4, 1)
    end

    # given a Pulley route, output a new Pulley route array with the solved angles
    function calculateSegments(route::Vector{Pulley2D.Pulley}, plotSegments::Bool=false)
        nr = size(route,1)
        solved = route #allocate the array

        for ir in 1:1:nr
            a = route[ir]
            b = route[Utility.iNext(ir,nr)]
            # println("a = ", a)
            # println("b = ", b)
            un =u"mm" # unit(a.center.x)
            if plotSegments
                Geometry2D.plotCircle(Pulley2D.pulley2Circle(a), "black")
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
                    solved[ir]                   = Pulley2D.Pulley(a.center, a.radius, a.axis, a.aArrive, thA, a.name )
                    solved[Utility.iNext(ir,nr)] = Pulley2D.Pulley(b.center, b.radius, b.axis, thB, b.aDepart, b.name )
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
    function routeToBeltSystem(route::Vector{Pulley2D.Pulley})
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
            if typeof(b) == Pulley2D.Pulley
              l += Pulley2D.calculateWrappedLength(b)
            end
            if typeof(b) == Segment
              l += b.length
            end
        end
        return l
    end

    function printRoute(route::Vector{Pulley2D.Pulley})
        for r in route
            un = unit(r.center.x)
            @printf("center[%3.3f, %3.3f] radius[%3.3f] arrive[%3.3f deg] depart[%3.3f deg]\n", ustrip(un, r.center.x), ustrip(un, r.center.y), ustrip(un, r.radius), rad2deg(ustrip(r.aArrive)), rad2deg(ustrip(r.aDepart)) )
        end
    end

    function toString(thing::Pulley2D.Pulley)
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
          if typeof(b) == Pulley2D.Pulley
            println("$i: ", Pulley2D.pulley2String(b))
            # Pulley2D.printPulley(b)
          else
            println("$i: ", toString(b))
          end
        end
        lTotal = calculateBeltLength(beltSystem)
        println("total belt length = $lTotal")

    end

    function plotBeltSystem(beltSystem; colorPulley="black",colorSegment="orange", linewidthBelt=4, plotUnit=u"mm")
        # nb = size(beltSystem,1)
        for (i,b) in enumerate(beltSystem)
            if typeof(b) == Pulley2D.Pulley
                Pulley2D.plotPulley(b, colorPulley=colorPulley, colorBelt=colorSegment, linewidthBelt=linewidthBelt, plotUnit=plotUnit)
                # Geometry2D.plotCircle(Pulley2D.pulley2Circle(b), colorPulley)
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
        pA = Pulley2D.Pulley( center=Geometry2D.Point(0u"mm",0u"mm"), radius=62u"mm", axis=uk)
        pB = Pulley2D.Pulley( center=Geometry2D.Point(146u"mm",80u"mm"), radius=43u"mm", axis=uk)
        pC = Pulley2D.Pulley( center=Geometry2D.Point(46u"mm",180u"mm"), radius=43u"mm", axis=uk)
        pD = Pulley2D.Pulley( center=Geometry2D.Point(0u"mm",100u"mm"), radius=4u"mm", axis=-uk) # axis is outside, rotates negatively, solves correctly

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
        pA = Pulley2D.PulleyKw( center=Geometry2D.Point(0u"m",0u"m"), radius=1u"m", axis=uk, "pA")
        pB = Pulley2D.PulleyKw( center=Geometry2D.Point(10u"m",0u"m"), radius=1u"m", axis=uk, "pB")
        belt = routeToBeltSystem( calculateSegments( [pA, pB], false) )
        lTotal = calculateBeltLength(belt) 
        println("testUnitPulleys: totalLength = [$lTotal] =?= 10+10+3.14+3.14=26.28m ")
        # printBeltSystem(belt)
    end

end #BeltSegment

end # BeltTransmission

# BeltTransmission.Pulley2D.dev()
# function dev()
    # @unit deg "deg" Degree 360/2*pi false
#   ctr = Geometry2D.Point(1u"mm", 3u"mm")
#   axx = Geometry2D.UnitVector(1,0,0)
#   # constructLiteral = Pulley(ctr, 10u"mm", axx, 90u"deg", 270u"deg" )
#   # constructLiteral = Pulley(ctr, 10u"mm", axx, 90u"degree", 270u"degree" )
#   # constructLiteral = BeltTransmission.Pulley2D.Pulley(ctr, 10u"mm", axx, 90deg, 270deg )
#   constructLiteral = BeltTransmission.Pulley2D.Pulley(ctr, 10u"mm", axx, 1u"rad", 2u"rad" )
#   print(constructLiteral)
#   # plot(constructLiteral)
#   # constructLiteral.plot()
# end
# dev()
