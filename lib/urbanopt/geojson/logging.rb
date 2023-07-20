# *********************************************************************************
# URBANopt (tm), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://github.com/urbanopt/urbanopt-geojson-gem/blob/develop/LICENSE.md
# *********************************************************************************

require 'logger'

module URBANopt
  module GeoJSON
    @@logger = Logger.new(STDERR)
    @@logger.progname = 'URBANopt::GeoJSON'

    def self.logger
      @@logger
    end

    def self.setLogger(l)
      @@logger = l
    end
  end
end
