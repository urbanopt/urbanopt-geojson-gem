# *********************************************************************************
# URBANopt™, Copyright (c) 2019-2021, Alliance for Sustainable Energy, LLC, and other
# contributors. All rights reserved.

# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:

# Redistributions of source code must retain the above copyright notice, this list
# of conditions and the following disclaimer.

# Redistributions in binary form must reproduce the above copyright notice, this
# list of conditions and the following disclaimer in the documentation and/or other
# materials provided with the distribution.

# Neither the name of the copyright holder nor the names of its contributors may be
# used to endorse or promote products derived from this software without specific
# prior written permission.

# Redistribution of this software, without modification, must refer to the software
# by the same designation. Redistribution of a modified version of this software
# (i) may not refer to the modified version by the same designation, or by any
# confusingly similar designation, and (ii) must refer to the underlying software
# originally provided by Alliance as “URBANopt”. Except to comply with the foregoing,
# the term “URBANopt”, or any confusingly similar designation may not be used to
# refer to any modified version of this software or any modified version of the
# underlying software originally provided by Alliance without the prior written
# consent of Alliance.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
# OF THE POSSIBILITY OF SUCH DAMAGE.
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

      attr_reader :zero

      attr_reader :one

      attr_reader :two

      attr_reader :ten

      attr_reader :eps

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

      attr_reader :new_vertices
    end # ScaleArea
  end # GeoJSON
end # URBANopt
