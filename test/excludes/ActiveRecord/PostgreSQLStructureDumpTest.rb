
# Rails 8.2 deprecates SchemaDumper.ignore_tables for schema_ignored_tables.
ignored_tables_owner = ActiveRecord.respond_to?(:schema_ignored_tables) ? ActiveRecord : ActiveRecord::SchemaDumper
ignored_tables_reader = ActiveRecord.respond_to?(:schema_ignored_tables) ? :schema_ignored_tables : :ignore_tables

setup do
	@ignore_tables = ignored_tables_owner.public_send(ignored_tables_reader)
	ignored_tables_owner.public_send(:"#{ignored_tables_reader}=", [])
	ARTest.config["connections"]["postgresql"] = { "arunit" => { "database" => ARTest.config["connections"]["postgis"]["arunit"]["database"] } }
end

teardown do
	ignored_tables_owner.public_send(:"#{ignored_tables_reader}=", @ignore_tables)
	ARTest.config["connections"].delete("postgresql")
end

exclude :test_structure_dump, TRIAGE_MSG + " / Likely due to CI installation of pg_dump vs postges"
