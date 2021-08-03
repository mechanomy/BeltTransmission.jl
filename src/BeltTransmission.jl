module BeltTransmission


module Pulley2D
    using Unitful
    using PyPlot #can use matplotlib arguments directly
    using Printf
    using StaticArrays #for defined-length arrays: SVector{3,T}
    using Geometry2D

    struct Pulley
        center::Geometry2D.Point #[x,y] of the pulley center
        radius::Unitful.Length
        axis::Geometry2D.UnitVector #unit vector in the direction of positive axis rotation
        aArrive::Geometry2D.Radian #angle of the point of tangency 
        aDepart::Geometry2D.Radian
    end
    Pulley(center::Geometry2D.Point, radius::Unitful.Length, axis::Geometry2D.UnitVector) = Pulley(center,radius,axis,0u"rad",0u"rad") # provide a helper constructor
    Pulley(; center::Geometry2D.Point, radius::Unitful.Length, axis::Geometry2D.UnitVector) = Pulley(center,radius,axis,0u"rad",0u"rad") # provide a helper constructor

    # Pulley( pulley::Pulley ) = Pulley( pulley.center, pulley.radius, pulley.axis, pulley.aArrive, pulley.aDepart ) #"copy" constructor?
    # Pulley(; x::Unitful.Length=0u"mm", y::Unitful.Length=0u"mm", radius::Unitful.Length=1u"mm", axis::Geometry2D.UnitVector=Geometry2D.uk, aArrive::Geometry2D.Radian=0u"rad", aDepart::Geometry2D.Radian=0u"rad") =
    #     Pulley(Geometry2D.Point(x, y), radius, axis, aArrive, aDepart )

    # Pulley(; xmm::Number=0, ymm::Number=0, radiusmm::Number=1) =
    #     Pulley(Geometry2D.Point(xmm*1.0u"mm", ymm*1.0*u"mm"), radiusmm*1.0*u"mm", Geometry2D.uk, 0.0u"rad", 0.0u"rad" ) #assumes mm, rad; doesn't work if the following is enabled

    # convert(::Type{Pulley}, x) = Pulley(x.center, x.radius, x.axis, x.aArrive, x.aDepart )

    function pulley2Circle(p::Pulley)
        return Geometry2D.Circle(p.center, p.radius)
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
            @printf("Cross: a+b/d=%f + %f / %f = %3f = %3f deg\n", ustrip(a.radius), ustrip(b.radius), ustrip(lCenter), ustrip(aCross), ustrip(aCross)*57)
            @printf("Para: a-b/d=%f + %f / %f = %3f = %3f deg\n", ustrip(a.radius), ustrip(b.radius), ustrip(lCenter), ustrip(aPara), ustrip(aPara)*57)
            @printf("A: four angles to tangent points: %3.3f %3.3f, %3.3f %3.3f\n", rad2deg(a1), rad2deg(a2), rad2deg(a3), rad2deg(a4))
            @printf("B: four angles to tangent points: %3.3f %3.3f, %3.3f %3.3f\n", rad2deg(b1), rad2deg(b2), rad2deg(b3), rad2deg(b4))

            println("A1B1: ", Geometry2D.isSegmentTangent(a, b, uconvert(u"rad", a1), uconvert(u"rad", b1)) )
            println("A2B2: ", Geometry2D.isSegmentTangent(a, b, uconvert(u"rad", a2), uconvert(u"rad", b2)) )
            println("A3B3: ", Geometry2D.isSegmentTangent(a, b, uconvert(u"rad", a3), uconvert(u"rad", b3)) )
            println("A4B4: ", Geometry2D.isSegmentTangent(a, b, uconvert(u"rad", a4), uconvert(u"rad", b4)) )

            #prove it
            Geometry2D.plotCircle(Pulley2D.pulley2Circle(a),"black")
            Geometry2D.plotCircle(Pulley2D.pulley2Circle(b),"black")
            x = [ustrip(a.center.x) + ustrip(a.radius)*cos(a1), ustrip(b.center.x) + ustrip(b.radius)*cos(b1)]
            y = [ustrip(a.center.y) + ustrip(a.radius)*sin(a1), ustrip(b.center.y) + ustrip(b.radius)*sin(b1)]
            plot(x,y, color="red") 
            x = [ustrip(a.center.x) + ustrip(a.radius)*cos(a2), ustrip(b.center.x) + ustrip(b.radius)*cos(b2)]
            y = [ustrip(a.center.y) + ustrip(a.radius)*sin(a2), ustrip(b.center.y) + ustrip(b.radius)*sin(b2)]
            plot(x,y, color="magenta") 
            x = [ustrip(a.center.x) + ustrip(a.radius)*cos(a3), ustrip(b.center.x) + ustrip(b.radius)*cos(b3)]
            y = [ustrip(a.center.y) + ustrip(a.radius)*sin(a3), ustrip(b.center.y) + ustrip(b.radius)*sin(b3)]
            plot(x,y, color="blue") 
            x = [ustrip(a.center.x) + ustrip(a.radius)*cos(a4), ustrip(b.center.x) + ustrip(b.radius)*cos(b4)]
            y = [ustrip(a.center.y) + ustrip(a.radius)*sin(a4), ustrip(b.center.y) + ustrip(b.radius)*sin(b4)]
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
        return Geometry2D.eqTol(ca4, 1) && Geometry2D.eqTol(cb4, 1)
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
                    solved[ir]           = Pulley2D.Pulley(a.center, a.radius, a.axis, a.aArrive, thA )
                    solved[Utility.iNext(ir,nr)] = Pulley2D.Pulley(b.center, b.radius, b.axis, thB, b.aDepart )
                end
                if ta && plotSegments
                    x = [ustrip(a.center.x) + ustrip(a.radius)*cos(thA), ustrip(b.center.x) + ustrip(b.radius)*cos(thB)]
                    y = [ustrip(a.center.y) + ustrip(a.radius)*sin(thA), ustrip(b.center.y) + ustrip(b.radius)*sin(thB)]
                    plot(x,y, color="green")
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
                l += abs( uconvert(u"rad", (b.aDepart-b.aArrive)) * b.radius)
            end
            if typeof(b) == Segment
                l += b.length
            end
        end
        return l
    end

    function printRoute(route::Vector{Pulley2D.Pulley})
        for r in route
            @printf("center[%3.3f, %3.3f] radius[%3.3f] arrive[%3.3f deg] depart[%3.3f deg]\n", ustrip(r.center.x), ustrip(r.center.y), ustrip(r.radius), rad2deg(ustrip(r.aArrive)), rad2deg(ustrip(r.aDepart)) )
        end
    end

    function toString(thing::Pulley2D.Pulley)
        str = @sprintf("Pulley: center[%3.3f, %3.3f] radius[%3.3f] arrive[%3.3f deg] depart[%3.3f deg]",
            ustrip(thing.center.x), ustrip(thing.center.y), ustrip(thing.radius),
            rad2deg(ustrip(thing.aArrive)), rad2deg(ustrip(thing.aDepart)) )
        # println("toString = ", str)
        return str
    end
    function toString(thing::Segment)
        str = @sprintf("Segment: depart[%3.3f, %3.3f] -- arrive[%3.3f, %3.3f] length[%3.3f]",
            ustrip(thing.depart.x), ustrip(thing.depart.y),
            ustrip(thing.arrive.x), ustrip(thing.arrive.y),
            ustrip(thing.length) )
        # println("toString = ", str)
        return str
    end

    # prints <beltSystem> by calling toString() on each element
    function printBeltSystem(beltSystem)
        for (i,b) in enumerate(beltSystem)
            println("$i: ", toString(b))
        end
        lTotal = calculateBeltLength(beltSystem)
        println("total belt length = $lTotal")

    end

    function plotBeltSystem(beltSystem; colorPulley="black",colorSegment="green")
        # nb = size(beltSystem,1)
        for (i,b) in enumerate(beltSystem)
            if typeof(b) == Pulley2D.Pulley
                plot(ustrip(b.center.x), ustrip(b.center.y), "o", color=colorPulley)
                Geometry2D.plotCircle(Pulley2D.pulley2Circle(b), colorPulley)
            end
            if typeof(b) == Segment #plot segments after pulleys
                x = ustrip([b.depart.x, b.arrive.x])
                y = ustrip([b.depart.y, b.arrive.y])
                plot(x,y, color=colorSegment, alpha=0.5)
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
        pA = Pulley2D.Pulley( center=Geometry2D.Point(0u"m",0u"m"), radius=1u"m", axis=uk)
        pB = Pulley2D.Pulley( center=Geometry2D.Point(10u"m",0u"m"), radius=1u"m", axis=uk)
        belt = routeToBeltSystem( calculateSegments( [pA, pB], false) )
        lTotal = calculateBeltLength(belt) 
        println("testUnitPulleys: totalLength = [$lTotal] =?= 10+10+3.14+3.14=26.28m ")
        # printBeltSystem(belt)
    end

end #BeltSegment

end # module
