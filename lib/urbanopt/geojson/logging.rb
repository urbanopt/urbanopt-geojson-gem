require 'logger';

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