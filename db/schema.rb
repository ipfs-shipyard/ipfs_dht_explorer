# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_11_02_151609) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_stat_statements"
  enable_extension "plpgsql"

  create_table "edges", force: :cascade do |t|
    t.integer "source_id"
    t.integer "target_id"
    t.boolean "reachable"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "nodes", force: :cascade do |t|
    t.string "node_id"
    t.string "multiaddrs", array: true
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
    t.index ["agent_version"], name: "index_nodes_on_agent_version"
    t.index ["country_iso_code"], name: "index_nodes_on_country_iso_code"
    t.index ["minor_go_ipfs_version"], name: "index_nodes_on_minor_go_ipfs_version"
  end

end
