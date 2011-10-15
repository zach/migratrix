require 'spec_helper'

# Migatrix loads Migration classes into its namespace. In order to
# test collision prevention, I needed to reach into Migratrix and
# mindwipe it of any migrations. Here's the shiv to do that. I
# originally put an API to do this on Migratrix but these specs are
# the only clients of it so I removed it again. If you find a
# legitimate use for it, feel free to re-add a remove_migration
# method and send me a patch.
def reset_migratrix!(migratrix)
  Migratrix.constants.map(&:to_s).select {|m| m =~ /.+Migration$/}.each do |migration|
    Migratrix.send(:remove_const, migration.to_sym)
  end
  migratrix.registered_migrations.clear
end

describe Migratrix::Migratrix do
  let (:migratrix) { Migratrix::Migratrix.new }

  it "exists (sanity check)" do
    Migratrix.should_not be_nil
    Migratrix.class.should == Module
    Migratrix.class.should_not == Class
    Migratrix::Migratrix.class.should_not == Module
    Migratrix::Migratrix.class.should == Class
    Migratrix.const_defined?("Migratrix").should be_true
  end

  describe "MigrationRegistry (needs to be extracted)" do
    before do
      reset_migratrix! migratrix
      Migratrix.class_eval("class PantsMigration < Migration; end")
      migratrix.register_migration "PantsMigration", Migratrix::PantsMigration
    end

    it "can register migrations by name" do
      migratrix.loaded?("PantsMigration").should be_true
      Migratrix.const_defined?("PantsMigration").should be_true
    end

    it "can fetch registered migration class" do
      migratrix.fetch_migration("PantsMigration").should == Migratrix::PantsMigration
    end

    it "raises fetch error when fetching unregistered migration" do
      lambda { migratrix.fetch_migration("arglebargle") }.should raise_error(KeyError)
    end
  end

  describe ".migrations_path" do
    it "uses ./lib/migrations by default" do
      migratrix.migrations_path.should == ROOT + "lib/migrations"
    end

    it "can be overridden" do
      migratrix.migrations_path = Pathname.new('/tmp')
      migratrix.migrations_path.should == Pathname.new("/tmp")
    end
  end

  describe "#valid_options" do
    it "returns the valid set of option keys" do
      migratrix.valid_options.should == ["limit", "where", "logger"]
    end
  end

  describe "#filter_options" do
    it "filters out invalid options" do
      options = migratrix.filter_options({ "pants" => 42, "limit" => 3})
      options["limit"].should == 3
      options.should_not have_key("pants")
    end
  end

  describe "#migration_name" do
    it "classifies the name and adds Migration" do
      migratrix.migration_name("shirt").should == "ShirtMigration"
    end

    it "handles symbols" do
      migratrix.migration_name(:socks).should == "SocksMigration"
    end

    it "preserves pluralization" do
      migratrix.migration_name(:pants).should == "PantsMigration"
      migratrix.migration_name(:shirts).should == "ShirtsMigration"
    end
  end

  describe "#create_migration" do
    before do
      reset_migratrix! migratrix
      migratrix.migrations_path = SPEC + "fixtures/migrations"
    end

    it "creates new migration by name with filtered options" do
      migration = migratrix.create_migration :marbles, { "cheese" => 42, "where" => "id > 100", "limit" => "100" }
      migration.class.should == Migratrix::MarblesMigration
      Migratrix::MarblesMigration.should_not be_migrated
      migration.options.should == { "where" => "id > 100", "limit" => "100" }
    end
  end

  describe ".migrate" do
    before do
      reset_migratrix! migratrix
      migratrix.migrations_path = SPEC + "fixtures/migrations"
    end

    it "loads migration and migrates it" do
      Migratrix::Migratrix.stub!(:new).and_return(migratrix)
      Migratrix::Migratrix.migrate :marbles
      Migratrix::MarblesMigration.should be_migrated
    end
  end
end

