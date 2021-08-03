
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
    # Pulley(center::Geometry2D.Point, radius::Unitful.Length, axis::Geometry2D.UnitVector) = Pulley(center,radius,axis,0u"rad",0u"rad") # provide a helper constructor
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
