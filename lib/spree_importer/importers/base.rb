 module SpreeImporter
  module Importers
    module Base
      extend ActiveSupport::Concern

      attr_writer :warnings
      attr_writer :errors

      module ClassMethods
        def target(klass)
          define_method :target do
            klass
          end
        end

        def match_header(h)
          h.kind == self.name.demodulize.underscore
        end

        def row_based
          include SpreeImporter::Importers::RowBased
        end

        def row_based?
          false
        end
      end

      def warnings
        @warnings ||= [ ]
      end

      def errors
        @errors ||= [ ]
      end

      def fetch_instance(params)
        instance = target.where(params).first
        if instance
          self.warnings << "Warning existing #{target} matches params #{params}"
          instance
        else
          target.new
        end
      end

      def val(headers, row, key)
        header   = headers[key]
        return nil if header.nil?

        v = row.field(header.index).try :strip
        v.blank?? nil : v
      end

      def props_and_ops_from_headers(headers, row)
        props_and_ops = [ ]

        headers.each do |_, h|
          if val headers, row, h.key
            props_and_ops << h.label
            props_and_ops << h.sanitized
            props_and_ops << h.option if h.option?
          end
        end

        props_and_ops.uniq!

        properties   = ::Spree::Property.where name: props_and_ops
        option_types = ::Spree::OptionType.where name: props_and_ops

        [ properties, option_types ]
      end
    end
  end
end
