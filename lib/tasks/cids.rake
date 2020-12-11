namespace :cids do
  task export: :environment do
    wants_count = 10
    path = '/data/ipfs/cids.csv'
    Cid.export(path, wants_count)
  end
end
