# TODO #

## CRITICAL FEATURES FOR 0.9.0 ##

(in no particular order)

* [ ] Transform#finalize_object should accept a symbol, and send that
  message to the Transform instance. E.g. `finalize_object: :my_func`
  would call Transform#my_func(object).

* [ ] Better logging--hard to tell where I'm at in a long migration
  from reading the log files

* [ ] PROGRESS bar/meter.

* [ ] Non-applied transform variables. I notice a pattern emerging
  where I'm sticking crap in hashes and then deleting the keys back
  out in finalize_object.
  
* [ ] finalize_object, and possibly other steps, need access to the
  source object.

* [ ] extract/apply shorthand for `extract_attribute:  ->(obj,attr) {
      obj.send(attr) }` and `apply_attribute: ->(obj,attr,value) {
      obj.send("#{attr}=", val) }`, e.g. `extract_attribute: :'.'`
      (yuck, find a better shorthand)

* [ ] Nested migrations and transforms. Given a projects app, when
  migrating a projec with tasks, it would be nice to say e.g. `tasks:
  has_many({options})` where options could contain `accessor: :tasks`,
  `transform: :my_task_transform`, or even `migration:
  my_registered_migration`. If you specify transform, it would only
  run that transformation and it's up to you to handle this in the
  load phase (perhaps with `before_load :save_tasks`?); if you specify
  a migration we may want to skip the extract phase, but for now in
  "just make it work" mode we'll go ahead and let the migration
  trigger a full migrate with a `where: 'id=...'` clause, etc.

* [ ] Nested transforms. For nested objects (perhaps in a flattening
  migration) it would be nice to be able to nest the transform, so
  that the transform for foo, which has\_many bars, has a line like
  bars: bar\_transform, etc. Right now I'm using nested lambdas, like
  so:
  
    >
    set\_transform :transform, {
      transform: { legacy\_id: :id,
                   name: :name,
                   children: ->(obj){ obj.children.map {|c|
                        {id: c[:id], name: c[:name]}}}
                 ...
                 }

  But what I'd really like to see is a way of navigating the object
  tree with nested hashes or transforms, etc.
  
* [ ] Investigate: if you write your own Migration and override
  #migrate, does it break all of the callbacks? If you write your own
  Load and override #load, does it break all of the load callbacks? I
  think it does....
  
* [ ] Crossing the Streams. Although we support the notion of multiple
  ETL streams, currently a transform or load only receive the single
  stream that matches their name (or that they have named). Need to
  either make it possible for a trasform to get at all of the
  extractors, or have e.g. `extractor: [:clothes, :tools]` cause
  `transform.transform` to receive `{clothes: [...], tools: [...]}`
  instead of always `[...]`.

* [ ] `transform.transform` and `load.load` should receive
  `migration.options`

* [ ] Migration Log

* [ ] Codify the strategy of merge transforms, e.g. perform a
  `find_or_create` in the transform instead of calling new. Again,
  technically the default Transform can do this for us but this seems
  like such a common case that it needs codifying.

* [ ] Handle duplicates. Whenever extracting a left-join query, the
  left-hand object will be duplicated on every child row.

* [ ] Iron out multirow composition. E.g. when extracting a
  left-joined query, the right-hand object on each row will be a
  member of the has_many collection for that object. But if we're
  transforming to NoSQL or an xml-based object, etc, this collection
  might simply be embedded on the parent object. We need to codify
  this notion that a row might simply update objects in the transform
  instead of always creating new ones.

* [ ] habtms - the worst of both worlds above. Every left AND right
  object might be new, might already exist, and might need to be
  accreted onto an existing document object. FUN! Make proofs of
  concepts of all of these.

* [ ] Get vanilla AR 1->1 migration working.

* [ ] Create before/after class methods and method call chains.

* [ ] Use around filters to log main method calls, even on
  client-extended classes
  
* [ ] console=true should become console=log_level  

* [ ] Consider having a `Migratrix::ModelBase < ActiveRecord::Base`
  base class with all the ActiveRecord migration helpers pre-mixed-in.
  Then users can define something like
  
    module Legacy
      class Base < Migratrix::ModelBase
        establish_connection :legacy
      end
    end
    
  ...and build up their legacy models from there.

* [ ] Get Hairy BFQ->n migration working, either as Multimodel (with
  tricksy joins in the legacy models)->Multimodel or SQL->Multimodel,
  both with find/create behavior on the dependent object output.
  **YIKES:** This implies that a complex migration must either have
  different load strategies for each *type* of data being loaded,
  and/or it must be able to defer to a separate migration entirely.
  
* [ ] Get a CSV migration working. This involves making either the extract
  or transform phase supply source and destination attribute names,
  and either the transform phase or the load phase must access those
  attribute values and write them to the CSV.
  
* [ ] Proof of Concept of iterative migrations (migrate a table, then
  the legacy table gets new data, so the next migration migrates the
  updates, inserts and deletes). (NOTE: This was REALLY hard to do in
  the prototype project--had to put update and delete triggers in the
  legacy database, and then bifurcate the tool into full_migrations
  and partial_migrations. It's okay if this gets pushed out after
  version 1.0.0)
  
## Critical Features for 1.0.0 ##  
 
* [ ] Documentation! Documentation! Documentation!
 
## Problems For Later ##

* [ ] Extract Component management in Migration. Right now Migratrion
  has a ton of duplicate code for extract, transform and load.
  (`self.set_load`, `self.extend_load`, `self.loads`, and `loads` is
  duplicated for `extractor`, `transform`, and `load`)
  
* Problem for later: What happens if we're doing a BFQ join query in
  batches of 1000, and each Load record is comprised of rand(100) rows
  in the SQL input, and a Load record spans the 1000 input rows?
  
* Problem for later: Consider lazy streams? Say we're migrating
  projects and tasks, and instead of saying limit=10 and getting 10
  tasks and taking our chances on however many projects that gets us,
  we say limit=10 *projects*. With lazy streams, instead of querying
  10 rows, we tell the loader something like 10.times { load_next },
  and it would get the next project and ALL of its tasks. The
  implication here is that you could get 5 tasks or 5,000; all you
  know for sure is that you got 10 projects. Since in this case
  migrating a Project makes sense as a cohesive unit, I think that's
  okay. (Also, todo for later, we could have options get steered to
  the appropriate areas, like projects:limit=10, tasks:limit=10, and
  now you'd get 10 projects with at most 10 tasks each. A seductively
  dark implication of this is that Load gets first crack at the
  options, and then decides which options get sent to which transforms
  and how, and how options get sent to the extractor.)
  
* Problem for later: JS (GW license)

* [ ] Refactor valid_options into a class method so you can say

    class Map < Transform
      valid_options "map", "foo", "bar"
      
  and have it magically mix itself into Transform's valid_options
  chain, and autosort, etc.

# TODONE #

This section is just a gathering place for done tasks so I can still
feel a sense of accomplishment, but without having to wade through
them all to get to the tasks that need doing.

* [x] BARF Extract Migratrix code into a central/main/controller
  class.

* [x] Fix the module-level API: `migrate!`, `logger` and `logger=` are
  all that are really necessary; everything else people can go through
  `Migratrix::Migratrix` to get at, or more likely directly to
  `Migratrix::Migration`, etc.
  
* [x] Reinstate the logging stuff. Migratrix should log to STDOUT by
  default, or somewhere else if redirected, and everything in the
  Migratrix namespace should share/reuse that logger. Singletons,
  anyone?
  
* [x] FIX the reinstated logging stuff to act like real loggers, so
  that we can inject the `Rails.logger` or a `Logger.new($stdout)`
  without having to muck about with streams.

* [x] 100% code coverage, because I *can*.

* [x] Parts of migratrix_spec.rb are testing migration.rb. Extract them.

* [x] Go ahead and commit the included -> extend atrocity with
  Loggable. It's annoying to have to `include Loggable; extend
  Loggable::ClassMethods` everywhere I just want #log and .log.
  _Better: just use ActiveSupport::Concern_.
  
* [x] Add Migration class name automatically to logging methods.

* [x] Get AR->Yaml constants migration working.

* [x] Extract out Extractor class

* [x] Fix class instance buglet

* [x] Extract out Transform class, transforms collection.

* [x] register_extractor, etc, so that we're not using magical load
  paths. This lets others write their own Extractors, Transforms and
  Loads, etc.

* [%] Refactor NotImplementedMethod specs to shared behavior

* [*] Move `Migratrix.valid_options` into migration, provide
  `valid_options` class method / DSL to allow subclasses to
  overwrite/extend the migratrix options. Then the migration class can
  handle its options its own way (for example a csv-based migration
  might permit a "headers" option)

* [x] Renege on the only-one-extractor idea. If you have data in two
  sources--like a YAML file and a MongoDB, you really have to have 2
  extractors. (Well, okay, you could write an Extractor that grabs
  stuff from both sources but we already have this notion of named
  transform and load streams, might as well have named extraction
  streams.)

* [*] Symbolize all the options keys and valid_options, or use
  HashWithIndifferentAccess.
  
* [*] Put dials and knobs (options) on Transform

* [*] Add nicer (Phase 3) syntax to Transform options. E.g.
  `transform_class` doesn't have to be a lambdba, it could actually BE
  a class....

* [*] Load

* [*] Load::YAML

* [*] Option inheritance--in migrations.

    class SomeMigration < Migration
      set_extractor :evens, :active_record, { where: 'id % 2 = 0'}
    end
    
    class ChildMigration < SomeMigration
      extend_extractor :evens, { source: Legacy::Children }
    end
    
    ChildMigration.new.extractor(:evens).options
    # => { where: 'id % 2 = 0', source: Legacy::Children }
  
## TODONE 0.8.0 ##

* [*] Rename Extractor -> Extraction. I've managed to keep Transform
  and Load from becoming Transformer and Loader; there's no reason to
  let extractor be different. (Note: was going to call this "Extract"
  but halfway through the rename I realized that "extract" as a noun
  has an existing, intuitive (and thus misleading) meaning. (E.g.
  "vanilla extract", "floral extract", "fruit extract", etc.)

* [x] Callbacks - `before_extract`, `after_load`, etc

* [x] Bug: inherit components by default! Child migrators should not
  need to call extend_* to inherit a component.

* [x] Default components. If you set_extract, et al, without a
  nickname, it should assign it to e.g. `:default`. So you can say
  e.g. `set_extract :source => Pants`. This is a sensible
  simplification since most migrations only have one stream.

* [x] Add includes, joins to ActiveRecord extractor

* [x] Allow procs as sources for extractions. Currently this bombs in
  the deep_copy.

* [x] Cascading where clauses? If the migration receives a where
  clause and the extractor already has one, combine them. E.g. if I
  have a SimpleWidgetsMigrator that calls `set_extraction
  :active_record, where: "type='simple'"` and the user calls
  `migrator.migrate where: 'id<10'` I'd like those two where clauses
  ganged together rather than overwritten. 
  
* [x] Load::ActiveRecord. Do we really need this? Do we need anything
  besides the default Load strategy? (Remember, the AR class is set in
  Transform, so save should just work...) YES, we need this, but for a
  different reason: we need to do update existing records rather than
  simply saving a new object every time.
  
* [*] "seen" cache on updates, at least by id. E.g. if we're saving
  projects with many tasks, allow a caching strategy to remember if
  we've already seen/updated a task, and then not re-update it after
  that.

^^^ New Done Stuff Goes here  


# TODON'T (YET) #

* [ ] Write generators, e.g. for

    rails g migratrix:constant_migration --namespace NewApp equipment name weight

which should emit the struct class, constant, and initializer loader, e.g.

    module NewApp
        class Equipment < Struct.new(:name, :weight); end
               
        EQUIPMENT = YAML.load_file(CONSTANTS_PATH + 'equipment.yml').inject({}) {|hash, object| hash[object[:id]] = Equipment.new(*object.values); hash }

etc.

* [ ] Register Extractor as an extractor, and allow overrides of
  everything. Then go back and rebuild ActiveRecord using the builder
  dsl.
  
