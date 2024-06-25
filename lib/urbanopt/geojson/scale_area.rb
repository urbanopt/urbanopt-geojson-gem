# *********************************************************************************
# URBANopt (tm), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://github.com/urbanopt/urbanopt-geojson-gem/blob/develop/LICENSE.md
# *********************************************************************************

require 'json'
require 'net/http'
require 'uri'
require 'openssl'
require 'bigdecimal/newton'

module Newton
  def self.jacobian(f, fx, x)
    Jacobian.jacobian(f, fx, x)
  end

  def self.ludecomp(a, n, zero = 0, one = 1)
    LUSolve.ludecomp(a, n, zero, one)
  end

  def self.lusolve(a, b, ps, zero = 0.0)
    LUSolve.lusolve(a, b, ps, zero)
  end
end

module URBANopt
  module GeoJSON
    class ScaleArea
      def initialize(vertices, desired_area, runner, eps)
        @vertices = vertices
        @centroid = OpenStudio.getCentroid(vertices)
        raise "Cannot compute centroid for '#{vertices}'" if @centroid.empty?

        @centroid = @centroid.get
        @desired_area = desired_area
        @new_vertices = vertices
        @runner = runner
        @zero = BigDecimal('0.0')
        @one  = BigDecimal('1.0')
        @two  = BigDecimal('2.0')
        @ten  = BigDecimal('10.0')
        @eps  = eps
      end

      attr_reader :zero, :one, :two, :ten, :eps, :new_vertices

      ##
      # Used to determine new scaled vertices, by iteratively passing in the perimeter distance to
      # minimise the difference of the new and scaled area. Returns the difference of the new area and desired area.
      #
      def values(x)
        @new_vertices = URBANopt::GeoJSON::Zoning.divide_floor_print(@vertices, x[0].to_f, @runner, scale = true)
        new_area = OpenStudio.getArea(@new_vertices)
        raise "Cannot compute area for '#{@new_vertices}'" if new_area.empty?

        new_area = new_area.get

        return [new_area - @desired_area]
      end
    end
  end
end
