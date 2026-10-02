# frozen_string_literal: true

require_relative "../test_helper"
require "tmpdir"

module PostGIS
  class SchemaCacheTest < ActiveSupport::TestCase
    def test_json_schema_cache_round_trips_spatial_columns
      skip "JSON schema cache needs Rails 8.2" unless defined?(ActiveRecord::ConnectionAdapters::JSONSchemaCacheSerializer)

      create_model
      pool = SpatialModel.connection_pool
      expected = pool.with_connection { |c| c.columns("spatial_models") }.index_by(&:name)

      Dir.mktmpdir do |dir|
        path = File.join(dir, "schema_cache.json")
        cache = ActiveRecord::ConnectionAdapters::SchemaCache.new
        cache.add(pool, "spatial_models")
        cache.dump_to(path)
        loaded = ActiveRecord::ConnectionAdapters::SchemaCache._load_from(path)
        columns = loaded.columns_hash(pool, "spatial_models")

        %w[latlon latlon_geo points path].each do |name|
          column = columns.fetch(name)
          original = expected.fetch(name)
          assert_kind_of ActiveRecord::ConnectionAdapters::PostGIS::Column, column
          assert_equal original.geometric_type, column.geometric_type
          assert_equal original.srid, column.srid
          assert_equal original.geographic?, column.geographic?
          assert_equal original.limit, column.limit
          assert_equal original.cast_type, column.cast_type
        end
      end
    end

    private

    def create_model
      SpatialModel.lease_connection.create_table(:spatial_models, force: true) do |t|
        t.column "latlon", :st_point, srid: 3785
        t.column "latlon_geo", :st_point, srid: 4326, geographic: true
        t.column "points", :multi_point, srid: 3785
        t.column "path", :line_string, srid: 3785
      end
      SpatialModel.reset_column_information
    end
  end
end
