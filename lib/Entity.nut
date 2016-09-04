class ORM.Entity {  
    static table = UNDEFINED;
    static fields = [];
    static traits = [];

    /**
     * Table with stored/loaded data
     * @type {Object}
     */
    __data = null;

    /**
     * Array that keeps names of modified fields
     * (changed since last save/load)
     * 
     * @type {Array}
     */
    __modified = null;

    /**
     * Field store information about 
     * fields that were attached to entity
     * 
     * @type {Object}
     */
    __fields = null;

    /**
     * Field that tracks if entity is destroyed
     * 
     * @type {Boolean}
     */
    __destroyed = false;

    /**
     * Field that tracks if the entity 
     * was ever persisted to storage
     * 
     * @type {Boolean}
     */
    __persisted = false;


    constructor() {
        this.__data = {};
        this.__modified = [];
        this.__fields = {};

        // this.__data["_uid"] <- _uid();
        // this.__data["_entity"] <- typeof(this);

        this.__attachField( ORM.Field.Integer({ name = "_uid", primary = true, autoinc = true }));
        this.__attachField( ORM.Field.String({ name = "_entity", value = typeof(this) }));

        // attach field described in entity class
        foreach (idx, field in this.fields) {
            this.__attachField(field);
        }

        // inherit traits described in entity class
        foreach (idx, trait in this.traits) {
            if (!(trait instanceof ORM.Trait.Interface)) {
                throw "ORM.Entity: you've tried to insert non-inherited trait. Dont do dis.";
            }

            // attach trait fields
            foreach (idx, field in trait.fields) {
                this.__attachField(field);
            }
            
            // registering methods of trait entities
            // foreach (idx, field in trait) {
            //     if (typeof(field) == "function") {
            //         dbg(idx);
            //     }
            // }
        }
    }

    /**
     * Attach (bind) field to this model
     * @param  {ORM.Field} field
     */
    function __attachField(field) {
        if (!(field instanceof ORM.Field.Basic)) {
            throw "ORM.Entity: you've tried to attach non-inherited field. Dont do dis.";
        }

        this.__data[field.__name] <- field.__value;
        this.__fields[field.__name] <- field;
    }

    /**
     * Method sets object field
     * and marks it as modified
     * 
     * @param {string} name
     * @param {mixed} value
     */
    function set(name, value) {
        if (!name in this.__data) {
            throw "ORM.Entity: couldn't insert non-described data as field: " + name;
        }

        this.__data[name] = value;
        this.__modified.push(value);
    }

    /**
     * Method gets value by field name
     * 
     * @param {string} name
     */
    function get(name) {
        return this[name];
    }

    /**
     * Meta impelemtation for set
     * @param {string} name
     * @param {mixed} value
     */
    function _set(name, value) {
        if (!name in this.__data) {
            throw null;
        }

        this.__data[name] = value;
        this.__modified.push(value);
    }

    /**
     * Meta implementation for get
     * @param  {string} name
     * @return {mixed}
     */
    function _get(name) {
        if (name in this.__data) {
            return this.__data[name];
        }

        throw null;
    }

    /**
     * Method exports data from model to plain object
     * @return {Object}
     */
    function export() {
        local object = {};

        foreach (idx, value in this.__data) {
            object[idx] <- value;
        }

        return object;
    }

    /**
     * Static method creates and "hydrates" 
     * (populates) model based on plain data
     * and returns created object
     * 
     * @param  {Object} data
     * @return {ORM.Entity}
     */
    static function hydrate(data) {
        local entity = this();

        // load data into model
        foreach (field, value in data) {
            if (field in entity.__data) {
                entity.__data[field] = value;
            }
        }

        // entity came from storage
        entity.__persisted = true;

        return entity;
    }

    /**
     * Method creates new query table
     * @return {ORM.Query} [description]
     */
    function __create() {
        local table_name = this.table.tolower();
        local table_fields = [];

        // compile fields data
        foreach (idx, field in this.__fields) {
            table_fields.push(field.__create());
        }

        // TODO: more custom index building

        // create query and fill data
        local query = ORM.Query("CREATE TABLE IF NOT EXISTS `:table` (:fields)");

        query.setParameter("table", table_name);
        query.setParameter("fields", ORM.Utils.Array.join(table_fields, ","));

        return query;
    }

    function save() {}
    function remove() {}
    static function findAll() {}
    static function findBy() {}
    static function findOneBy() {}
}