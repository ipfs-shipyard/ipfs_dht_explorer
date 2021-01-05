# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2021_01_05_124803) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_stat_statements"
  enable_extension "plpgsql"

  create_table "cids", force: :cascade do |t|
    t.string "cid"
    t.integer "wants_count", default: 0
    t.string "content_type"
    t.bigint "content_length"
    t.datetime "last_loaded_at"
    t.index ["cid"], name: "index_cids_on_cid", unique: true
    t.index ["wants_count"], name: "index_cids_on_wants_count"
  end

  create_table "edges", force: :cascade do |t|
    t.integer "source_id"
    t.integer "target_id"
    t.boolean "reachable"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "exports", force: :cascade do |t|
    t.string "filename"
    t.string "kind"
    t.string "cid"
    t.integer "size"
    t.integer "records"
    t.text "description"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "nodes", force: :cascade do |t|
    t.string "node_id"
    t.string "multiaddrs", default: [], array: true
    t.boolean "reachable"
    t.string "agent_version"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "peers_count", default: 0
    t.string "protocols", default: [], array: true
    t.string "country_iso_code"
    t.string "country_name"
    t.string "most_specific_subdivision_name"
    t.string "city_name"
    t.string "postal_code"
    t.integer "accuracy_radius"
    t.float "latitude"
    t.float "longitude"
    t.string "network"
    t.integer "autonomous_system_number"
    t.string "autonomous_system_organization"
    t.string "minor_go_ipfs_version"
    t.string "patch_go_ipfs_version"
    t.string "domains", default: [], array: true
    t.integer "sightings", default: 0
    t.integer "wants_count", default: 0
    t.boolean "pl", default: false
    t.datetime "last_crawled"
    t.string "ip4_addresses", default: [], array: true
    t.index ["agent_version"], name: "index_nodes_on_agent_version"
    t.index ["country_iso_code"], name: "index_nodes_on_country_iso_code"
    t.index ["minor_go_ipfs_version"], name: "index_nodes_on_minor_go_ipfs_version"
    t.index ["node_id"], name: "index_nodes_on_node_id", unique: true
    t.index ["updated_at"], name: "index_nodes_on_updated_at"
  end

  create_table "wants", force: :cascade do |t|
    t.integer "node_id"
    t.integer "cid_id"
    t.datetime "created_at", null: false
    t.index ["cid_id"], name: "index_wants_on_cid_id"
    t.index ["created_at"], name: "index_wants_on_created_at"
    t.index ["node_id"], name: "index_wants_on_node_id"
  end

end
